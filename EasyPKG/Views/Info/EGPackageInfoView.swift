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
								title: .localized("Are you sure you want to delete %ld files?", arguments: Int32(_selectedPaths.count)),
								style: .critical,
								primaryButton: (.localized("Delete"), true)
							) {
								helperManager.removeFiles(for: _selectedPaths) { success in
									if !success {
										NSAlert.present(
											title: .localized("Failed to delete some files."),
											cancelButtonTitle: .localized("OK")
										) {}
									} else {
										_selectedPaths = []
									}
								}
							}
						}
						
						Button(.localized("Delete Selected Paths & Forget")) {
							NSAlert.present(
								title: .localized("Are you sure you want to delete %ld files and then forget the package afterwards?", arguments: receipt.packageName, Int32(_selectedPaths.count)),
								style: .critical,
								primaryButton: (.localized("Delete & Forget"), true)
							) {
								helperManager.removeFiles(for: _selectedPaths) { success in
									if !success {
										NSAlert.present(
											title: .localized("Failed to delete some files for %@."),
											cancelButtonTitle: .localized("OK")
										) {}
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
					
//					Button(.localized("Uninstall")) {
//						NSAlert.present(
//							title: .localized("Are you sure you want to uninstall %@?", arguments: receipt.packageName),
//							style: .critical,
//							primaryButton: (.localized("Uninstall"), true)
//						) {
//							
//						}
//					}
//					.buttonStyle(.borderedProminent)
//					.tint(.red)
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
			EGUtils.listPathsFromDirectoryEnumerator(
				enumerator: enumerator,
				prefix: receipt.packageInstallPath,
				installPaths: &_receiptInstallPaths
			)
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
					selectedPaths: $_selectedPaths,
					expandedNodes: $_expandedNodes
				)
			}
		)
	}
}
