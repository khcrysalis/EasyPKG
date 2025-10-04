//
//  PackageInfoView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageInfoView
struct EGPackageInfoView: View {
	@State private var _receiptInstallPaths: [String] = []
	@State private var _selectedPaths: Set<String> = []
	@State private var _expandedNodes: Set<UUID> = []
	@State private var _isDescriptivePresenting: Bool = false
	@State private var _filePathsView: AnyView? = nil
	
	@ObservedObject var helperManager: EGHelperManager
	var receipt: PKReceipt
	@Binding var volume: String
	var forgetPackageAction: () -> ()
	
	// MARK: Body
	
	var body: some View {
		VStack {
			VStack(alignment: .leading) {
				HStack {
					EGFileImage()
					Text(receipt.packageName)
						.font(.largeTitle)
						.frame(maxWidth: .infinity, alignment: .leading)
					Spacer()
					Button("?") {
						_isDescriptivePresenting = true
					}
				}
				Group {
					Text(verbatim: "\(receipt.packageVersion) • \(receipt.packageIdentifier)")
					Text(verbatim: .localized("Installed on %@", arguments: receipt.installDate.description))
					Text(.localized("Unpackaged at %@", receipt.packageInstallPath))
				}
				.font(.subheadline)
				.textSelection(.enabled)
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			Group {
				ZStack {
					if let pathsView = _filePathsView {
						pathsView.opacity(_filePathsView == nil ? 0 : 1)
					} else {
						List{}.opacity(0.3)
						ProgressView()
					}
				}
			}
			.listStyle(.bordered)
			.padding(.vertical, 6)
			
			if !receipt.isHidden {
				HStack {
					Group {
						Button(.localized("Deselect All")) {
							_selectedPaths = []
						}
						
						Spacer()
						
						Button(.localized("Delete Selected Paths")) {
							NSAlert.present(
								title: .localized("Are you sure you want to delete %ld files?", arguments: _selectedPaths.count),
								style: .critical,
								primaryButton: (.localized("Delete"), true)
							) {
								helperManager.removeFiles(for: _selectedPaths) { success in
									if !success {
										_showDeleteError(for: receipt)
									} else {
										_selectedPaths = []
									}
								}
							}
						}
						
						Button(.localized("Delete Selected Paths & Forget")) {
							NSAlert.present(
								title: .localized("Are you sure you want to delete %ld files and then forget the package afterwards?", arguments: _selectedPaths.count),
								style: .critical,
								primaryButton: (.localized("Delete & Forget"), true)
							) {
								helperManager.removeFiles(for: _selectedPaths) { success in
									if !success {
										_showDeleteError(for: receipt)
									} else {
										_selectedPaths = []
										forgetPackageAction()
									}
								}
							}
						}
					}
					.disabled(_selectedPaths.isEmpty)
					
					Button(.localized("Forget")) {
						NSAlert.present(
							title: .localized("Are you sure you want to forget %@?", arguments: receipt.packageName),
							message: .localized("Forgetting a package will unregister it from your system, but won't delete any files associated with it."),
							style: .informational,
							primaryButton: (.localized("Forget"), false)
						) {
							forgetPackageAction()
						}
					}
					
					Button(.localized("Uninstall")) {
						NSAlert.present(
							title: .localized("Are you sure you want to uninstall %@?", arguments: receipt.packageName),
							message: .localized("This will delete most files associated with the package and then it will unregister it from your system. This is a dangerous action."),
							style: .critical,
							primaryButton: (.localized("Uninstall"), true)
						) {
							helperManager.removeFiles(for: receipt.listUniqueFilesToDelete(fromVolume: volume)) { success in
								if !success {
									_showDeleteError(for: receipt)
								} else {
									_selectedPaths = []
									forgetPackageAction()
								}
							}
						}
					}
					.buttonStyle(.borderedProminent)
					.tint(.red)
				}
			}
		}
		.navigationTitle(receipt.packageName)
		.padding()
		.onAppear {
			_loadData()
			_updatePaths()
		}
		.sheet(isPresented: $_isDescriptivePresenting) {
			EGPackageDescriptiveInfoView(receipt: receipt, volume: volume)
		}
	}
	
	// MARK: Load
	
	private func _loadData() {
		if let enumerator = receipt._directoryEnumerator() as? NSEnumerator {
			_receiptInstallPaths = (enumerator.allObjects as? [String] ?? []).map {
				receipt.packageInstallPath + $0
			}
		}
	}
	
	private func _updatePaths() {
		self._filePathsView = nil
		
		DispatchQueue.global().async {
			let paths = _createChartView()
			
			DispatchQueue.main.async {
				withAnimation(.easeIn(duration: 0.3)) {
					self._filePathsView = paths
				}
			}
		}
	}
	
	private func _createChartView() -> AnyView {
		AnyView(
			List {
				EGPackagePathsDisclosureView(
					node: EGPathNode.buildPathTree(from: _receiptInstallPaths),
					isHidden: receipt.isHidden,
					disabledPaths: receipt.listUniqueFilesToExclude(fromVolume: volume),
					selectedPaths: $_selectedPaths,
					expandedNodes: $_expandedNodes
				)
			}
		)
	}
	
	private func _showDeleteError(for receipt: PKReceipt) {
		NSAlert.present(
			title: .localized("Failed to delete some files for %@.", arguments: receipt.packageName),
			cancelButtonTitle: .localized("OK")
		) {}
	}
}
