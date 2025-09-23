//
//  ContentView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageListView
struct EGPackageListView: View {
	@StateObject private var _helperManager = EGHelperManager()
	@AppStorage("epkg.defaultVolume") private var _defaultVolume: String = "/"
	@AppStorage("epkg.showHiddenPackages") private var _showHiddenPackages: Bool = false
	
	@State private var _selectedFilter: PackageFilter = .default
	@State private var _normalPackages: [PKReceipt] = []
	@State private var _hiddenPackages: [PKReceipt] = []
	@State private var _selectedPackage: PKReceipt? = nil
	@State private var _isHistoryPresenting: Bool = false
	
	private var _groupedByDate: [(day: Date, packages: [PKReceipt])] {
		let all = _normalPackages + (_showHiddenPackages ? _hiddenPackages : [])
		
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
			List(selection: $_selectedPackage) {
				if _selectedFilter == .default {
					Section(.localized("Installed Packages")) {
						ForEach(_normalPackages, id: \.self) { receipt in
							NavigationLink(value: receipt) {
								_packageRow(receipt)
							}
						}
					}
					
					if _showHiddenPackages {
						Section(.localized("Hidden Installed Packages")) {
							ForEach(_hiddenPackages, id: \.self) { receipt in
								NavigationLink(value: receipt) {
									_packageRow(receipt)
								}
							}
						}
					}
				}
				
				if _selectedFilter == .date {
					ForEach(_groupedByDate, id: \.day) { group in
						Section(header: Text(group.day, style: .date)) {
							ForEach(group.packages, id: \.self) { receipt in
								_packageRow(receipt)
							}
						}
					}
				}
			}
			.navigationTitle(.localized("Packages"))
			.listStyle(.sidebar)
			.toolbar {
				ToolbarItemGroup {
					Picker(.localized("Filter"), selection: $_selectedFilter) {
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
				if let receipt = _selectedPackage {
					EGPackageInfoView(
						helperManager: _helperManager,
						receipt: receipt,
						volume: $_defaultVolume,
						normalPackages: $_normalPackages,
						hiddenPackages: $_hiddenPackages,
						selectedPackage: $_selectedPackage
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
						_isHistoryPresenting = true
					} label: {
						Label(.localized("History"), systemImage: "clock")
					}
					
					SettingsLink {
						Label(.localized("Settings"), systemImage: "gear")
					}
				}
			}
		}
		.onAppear(perform: _loadPackages)
		.onChange(of: _defaultVolume) { _, _ in
			_loadPackages()
		}
		.onChange(of: _showHiddenPackages) { _, _ in
			_loadPackages()
		}
		.onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
			Task {
				await _helperManager.manageHelperTool()
			}
			_loadPackages()
		}
		.sheet(isPresented: $_isHistoryPresenting) {
			EGHistoryListView()
		}
		.navigationSubtitle(.localized("Using PackageKit.framework on macOS %@", getMacOSVersion()))
	}
	
	// MARK: Load
	
	private func _loadPackages() {
		let allPackages = EGUtils.receiptsOnVolume(atPath: _defaultVolume)
		
		_normalPackages = allPackages.filter { pkg in
			guard let id = pkg.packageIdentifier() as? String else { return false }
			return !EGUtils.hiddenPackageIdentifiers().contains { hidden in id.contains(hidden) }
		}
		
		_hiddenPackages = allPackages.filter { pkg in
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
	
	private func _packageRow(_ receipt: PKReceipt) -> some View {
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
