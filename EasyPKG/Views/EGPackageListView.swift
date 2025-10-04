//
//  EGPackageListView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - EGPackageListView Filter
extension EGPackageListView {
	enum PackageFilter: String, CaseIterable, Identifiable {
		case `default` = "default"
		case date = "date"
		
		var id: String { rawValue }
		
		var localizedName: String {
			switch self {
			case .default:	"Default".localized()
			case .date:		"Date".localized()
			}
		}
	}
}

// MARK: - PackageListView
struct EGPackageListView: View {
	@StateObject private var _helperManager = EGHelperManager()
	@AppStorage("epkg.defaultVolume") private var _defaultVolume: String = "/"
	@AppStorage("epkg.showHiddenPackages") private var _showHiddenPackages: Bool = false
	
	@State private var _selectedFilter: PackageFilter = .default
	@State private var _packages: [PKReceipt] = []
	@State private var _selectedPackage: PKReceipt? = nil
	@State private var _isHistoryPresenting: Bool = false
	
	// MARK: Grouped by install date
	private var _groupedByDate: [(day: Date, packages: [PKReceipt])] {
		let visiblePackages = _packages.filter { !_showHiddenPackages ? !$0.isHidden : true }
		let grouped = Dictionary(grouping: visiblePackages) { pkg -> Date in
			pkg.installDate
		}
		return grouped.keys.sorted(by: >).map { day in
			(day, grouped[day] ?? [])
		}
	}
	
	// MARK: Body
	var body: some View {
		NavigationSplitView {
			List(selection: $_selectedPackage) {
				switch _selectedFilter {
				case .default: _defaultSections()
				case .date: _dateSections()
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
						forgetPackageAction: {
							_helperManager.removeFiles(for: Set(receipt.receiptStoragePaths)) { success in
								if success {
									_packages.removeAll { $0 == receipt }
									_selectedPackage = nil
								} else {
									NSAlert.present(
										title: .localized("Failed to forget %@.", arguments: receipt.packageName),
										cancelButtonTitle: "OK"
									) {}
								}
							}
						}
					)
					.id(receipt.packageIdentifier)
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
		.onChange(of: _defaultVolume) { _,_ in _loadPackages() }
		.onChange(of: _showHiddenPackages) { _,_ in _loadPackages() }
		.onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
			Task { 
				await _helperManager.manageHelperTool()
				await MainActor.run() {
					_loadPackages()
				}
			}
		}
		.sheet(isPresented: $_isHistoryPresenting) {
			EGHistoryListView()
		}
		.navigationSubtitle(.localized("Using PackageKit.framework on macOS %@", EGUtils.getMacOSVersion()))
	}

	// MARK: Load
	
	private func _loadPackages() {
		_packages = PKReceipt.getReceiptsOnVolume(atPath: _defaultVolume)
	}

	// MARK: Sections
	
	@ViewBuilder
	private func _defaultSections() -> some View {
		Section(.localized("Installed Packages")) {
			ForEach(_packages.filter { !$0.isHidden }, id: \.packageIdentifier) { receipt in
				NavigationLink(value: receipt) { 
					_packageRow(receipt) 
				}
			}
		}
		
		if _showHiddenPackages {
			Section(.localized("Hidden Installed Packages")) {
				ForEach(_packages.filter(\.isHidden), id: \.packageIdentifier) { receipt in
					NavigationLink(value: receipt) { 
						_packageRow(receipt) 
					}
				}
			}
		}
	}

	@ViewBuilder
	private func _dateSections() -> some View {
		ForEach(_groupedByDate, id: \.day) { group in
			Section(header: Text(group.day, style: .date)) {
				ForEach(group.packages, id: \.packageIdentifier) { receipt in
					NavigationLink(value: receipt) { 
						_packageRow(receipt) 
					}
				}
			}
		}
	}
	
	private func _packageRow(_ receipt: PKReceipt) -> some View {
		HStack {
			EGFileImage()
			
			EGLabeledContent(
				title: receipt.packageName,
				description: "\(receipt.packageVersion) • \(receipt.packageIdentifier)"
			)
			
			if receipt.isHidden {
				Spacer()
				Image(systemName:  "eye.slash").foregroundStyle(.secondary)
			}
		}
	}
}

