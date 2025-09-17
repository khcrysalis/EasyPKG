//
//  ContentView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageListView
struct EGPackageListView: View {
	@StateObject private var helperManager = EGHelperManager()
	
	@AppStorage("epkg.defaultVolume") var defaultVolume: String = "/"
	@AppStorage("epkg.showHiddenPackages") var showHiddenPackages: Bool = false
	
	@State private var selectedFilter: PackageFilter = .default
	@State private var normalPackages: [PKReceipt] = []
	@State private var hiddenPackages: [PKReceipt] = []
	@State private var selectedPackage: PKReceipt? = nil
	@State private var isHistoryPresenting: Bool = false
	
	private var groupedByDate: [(day: Date, packages: [PKReceipt])] {
		let all = normalPackages + (showHiddenPackages ? hiddenPackages : [])
		
		let grouped = Dictionary(grouping: all) { pkg -> Date in
			if let date = pkg.installDate() as? Date {
				return Calendar.current.startOfDay(for: date)
			}
			return Date.distantPast
		}
		
		return grouped.keys.sorted(by: >).map { day in
			(day, grouped[day] ?? [])
		}
	}
	
	// MARK: Body
	
	var body: some View {
		NavigationSplitView {
			List(selection: $selectedPackage) {
				if selectedFilter == .default {
					Section(.localized("Installed Packages")) {
						ForEach(normalPackages, id: \.self) { receipt in
							NavigationLink(value: receipt) {
								packageRow(receipt)
							}
						}
					}
					
					if showHiddenPackages {
						Section(.localized("Hidden Installed Packages")) {
							ForEach(hiddenPackages, id: \.self) { receipt in
								NavigationLink(value: receipt) {
									packageRow(receipt)
								}
							}
						}
					}
				}
				
				if selectedFilter == .date {
					ForEach(groupedByDate, id: \.day) { group in
						Section(header: Text(group.day, style: .date)) {
							ForEach(group.packages, id: \.self) { receipt in
								packageRow(receipt)
							}
						}
					}
				}
			}
			.navigationTitle(.localized("Packages"))
			.listStyle(.sidebar)
			.toolbar {
				ToolbarItemGroup {
					Picker(.localized("Filter"), selection: $selectedFilter) {
						ForEach(PackageFilter.allCases) { filter in
							Text(filter.localizedName).tag(filter)
						}
					}
					.labelsHidden()
					.pickerStyle(.segmented)
				}
			}
		} detail: {
			Group {
				if let receipt = selectedPackage {
					EGPackageInfoView(
						helperManager: helperManager,
						receipt: receipt,
						volume: $defaultVolume,
						normalPackages: $normalPackages,
						hiddenPackages: $hiddenPackages,
						selectedPackage: $selectedPackage
					)
					.id(receipt.packageIdentifier() as! String)
				} else {
					ContentUnavailableView(
						.localized("Select a Package"),
						systemImage: "archivebox",
						description: Text(.localized("Choose a package from the sidebar to view details."))
					)
				}
			}
			.toolbar {
				ToolbarItemGroup {
					Button {
						isHistoryPresenting = true
					} label: {
						Label(.localized("History"), systemImage: "clock")
					}
					
					SettingsLink {
						Label(.localized("Settings"), systemImage: "gear")
					}
				}
			}
		}
		.onAppear(perform: loadPackages)
		.onChange(of: defaultVolume) { _, _ in
			loadPackages()
		}
		.onChange(of: showHiddenPackages) { _, _ in
			loadPackages()
		}
		.onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
			Task {
				await helperManager.manageHelperTool()
			}
			loadPackages()
		}
		.sheet(isPresented: $isHistoryPresenting) {
			EGHistoryListView()
		}
		.navigationSubtitle(.localized("Using PackageKit.framework on macOS %@", getMacOSVersion()))
	}
	
	// MARK: Load
	
	private func loadPackages() {
		let allPackages = EGUtils.receiptsOnVolume(atPath: defaultVolume)
		
		normalPackages = allPackages.filter { pkg in
			guard let id = pkg.packageIdentifier() as? String else { return false }
			return !EGUtils.hiddenPackageIdentifiers().contains { hidden in id.contains(hidden) }
		}
		
		hiddenPackages = allPackages.filter { pkg in
			guard let id = pkg.packageIdentifier() as? String else { return false }
			return EGUtils.hiddenPackageIdentifiers().contains { hidden in id.contains(hidden) }
		}
	}
	
	// MARK: Helpers
	
	func getMacOSVersion() -> String {
		let osVersion = ProcessInfo.processInfo.operatingSystemVersion
		return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
	}
	
	// MARK: Builders
	
	private func packageRow(_ receipt: PKReceipt) -> some View {
		HStack {
			EGFileImage()
			LabeledContent(
				receipt._packageName() as? String ?? .localized("Unknown"),
				value: "\(receipt.packageVersion()! as! String) • \(receipt.packageIdentifier()! as! String)"
			)
			.labeledContentStyle(.vertical)
		}
	}
}

// MARK: - EGPackageListView (extension): Filter
extension EGPackageListView {
	enum PackageFilter: String, CaseIterable, Identifiable {
		case `default` = "default"
		case date = "date"
		
		var id: String { rawValue }
		
		var localizedName: String {
			switch self {
			case .default: return "Default".localized()
			case .date: return "Date".localized()
			}
		}
	}
}
