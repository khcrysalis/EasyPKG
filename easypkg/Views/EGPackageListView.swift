//
//  ContentView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageListView
struct EGPackageListView: View {
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
					Section("Installed Packages") {
						ForEach(normalPackages, id: \.self) { receipt in
							NavigationLink(value: receipt) {
								packageRow(receipt)
							}
						}
					}
					
					if showHiddenPackages {
						Section("Hidden Installed Packages") {
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
			.navigationTitle("Packages")
			.listStyle(.sidebar)
			.toolbar {
				ToolbarItemGroup {
					Picker("Filter", selection: $selectedFilter) {
						ForEach(PackageFilter.allCases) { filter in
							Text(filter.rawValue).tag(filter)
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
						receipt: receipt,
						volume: defaultVolume
					)
					.id(receipt.packageIdentifier() as! String)
				} else {
					ContentUnavailableView(
						"Select a Package",
						systemImage: "archivebox",
						description: Text("Choose a package from the sidebar to view details.")
					)
				}
			}
			.toolbar {
				ToolbarItemGroup {
					Button {
						isHistoryPresenting = true
					} label: {
						Label("History", systemImage: "clock")
					}
					
					SettingsLink {
						Label("Settings", systemImage: "gear")
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
		.sheet(isPresented: $isHistoryPresenting) {
			EGHistoryListView()
		}
		.navigationSubtitle("Using PackageKit.framework on macOS \(getMacOSVersion())")
	}
	
	// MARK: Load
	
	private func loadPackages() {
		print("loading")
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
				receipt._packageName() as? String ?? "Unknown",
				value: "\(receipt.packageVersion()! as! String) • \(receipt.packageIdentifier()! as! String)"
			)
			.labeledContentStyle(.vertical)
		}
	}
}

// MARK: - EGPackageListView (extension): Filter
extension EGPackageListView {
	enum PackageFilter: String, CaseIterable, Identifiable {
		case `default` = "Default"
		case date = "Date"
		
		var id: String { rawValue }
	}
}
