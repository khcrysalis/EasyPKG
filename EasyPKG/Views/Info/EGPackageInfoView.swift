//
//  PackageInfoView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageInfoView
struct EGPackageInfoView: View {
	@State private var _prefixPath: String = ""
	@State private var _prefixSeperator: String = ""
	@State private var _receiptInstallPaths: [String] = []
	@State private var _selectedPaths: Set<String> = []
	@State private var _expandedNodes: Set<UUID> = []
	@State private var _isDescriptivePresenting: Bool = false
	@State private var _filePathsView: AnyView? = nil
	
	@State private var _isDeleteAlertPresenting = false
	@State private var _isForgetDeleteAlertPresenting = false
	@State private var _isForgetAlertPresenting = false
	@State private var _isAlertPresenting = false
	@State private var _alertTitle = ""
	
	@ObservedObject var helperManager: EGHelperManager
	var receipt: PKReceipt
	@Binding var volume: String
	@Binding var normalPackages: [PKReceipt]
	@Binding var hiddenPackages: [PKReceipt]
	@Binding var selectedPackage: PKReceipt?
	
	var body: some View {
		VStack {
			VStack(alignment: .leading) {
				HStack {
					EGFileImage()
					Text(receipt._packageName() as? String ?? .localized("Unknown"))
						.font(.largeTitle)
						.frame(maxWidth: .infinity, alignment: .leading)
					Spacer()
					Button("?") {
						_isDescriptivePresenting = true
					}
				}
				Group {
					Text(verbatim: "\(receipt.packageVersion()! as! String) • \(receipt.packageIdentifier()! as! String)")
					Text(verbatim: .localized("Installed on %@", arguments: (receipt.installDate() as! Date).description))
					Text(.localized("Unpackaged at %@", _prefixPath))
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
			
			HStack {
				Group {
					Button(.localized("Deselect All")) {
						_selectedPaths = []
					}
					
					Spacer()
					
					Button(.localized("Delete Selected Paths")) {
						_isDeleteAlertPresenting = true
					}
					
					Button(.localized("Delete Selected Paths & Forget")) {
						_isForgetDeleteAlertPresenting = true
					}
				}
				.disabled(_selectedPaths.isEmpty)
				
				Button(.localized("Forget")) {
					_isForgetAlertPresenting = true
				}
			}
		}
		.padding(4)
		.onAppear {
			_loadData()
			_updatePaths()
		}
		.sheet(isPresented: $_isDescriptivePresenting) {
			EGPackageDescriptiveInfoView(receipt: receipt, volume: volume)
		}
		.alert(_alertTitle, isPresented: $_isAlertPresenting, actions: {
			Button("OK", role: .cancel) { }
		})
		.alert(.localized("Are you sure you want to delete the selected files?"), isPresented: $_isDeleteAlertPresenting) {
			Button(.localized("Delete Selected Paths"), role: .destructive) {
				helperManager.removeFiles(for: _selectedPaths) { success in
					if !success {
						_alertTitle = "Failed to delete \(receipt._packageName() as? String ?? .localized("Unknown"))"
						_isAlertPresenting = true
					} else {
						_selectedPaths = []
					}
				}
			}
			Button(.localized("Cancel"), role: .cancel) { }
		}
		.alert(.localized("Are you sure you want to forget this package and delete selected files?"), isPresented: $_isForgetDeleteAlertPresenting) {
			Button(.localized("Delete Selected Paths & Forget"), role: .destructive) {
				helperManager.removeFiles(for: _selectedPaths) { success in
					if !success {
						_alertTitle = "Failed to delete & forget \(receipt._packageName() as? String ?? .localized("Unknown"))"
						_isAlertPresenting = true
					} else {
						_selectedPaths = []
						_forget(for: receipt) { success in
							if !success {
								_alertTitle = "Failed to forget \(receipt._packageName() as? String ?? .localized("Unknown"))"
								_isAlertPresenting = true
							}
						}
					}
				}
			}
			Button(.localized("Cancel"), role: .cancel) { }
		}
		.alert(.localized("Are you sure you want to forget this package?"), isPresented: $_isForgetAlertPresenting) {
			Button(.localized("Forget"), role: .destructive) {
				_forget(for: receipt) { success in
					if !success {
						_alertTitle = "Failed to forget \(receipt._packageName() as? String ?? .localized("Unknown"))"
						_isAlertPresenting = true
					}
				}
			}
			Button(.localized("Cancel"), role: .cancel) { }
		}
		.padding()
	}
	
	// MARK: Load
	
	private func _loadData() {
		let prefix = receipt.installPrefixPath()! as! String
		_prefixPath = prefix.hasPrefix("/") ? prefix : volume + prefix
		_prefixSeperator = _prefixPath.hasSuffix("/") ? "" : "/"
		
		if let enumerator = receipt._directoryEnumerator() as? NSEnumerator {
			EGUtils.listPathsFromDirectoryEnumerator(
				enumerator: enumerator,
				prefix: _prefixPath + _prefixSeperator,
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
					selectedPaths: $_selectedPaths,
					expandedNodes: $_expandedNodes
				)
				.padding(.leading, 1)
			}
		)
	}
	
	private func _forget(for receipt: PKReceipt, completion: @escaping (Bool) -> Void) {
		if let p = receipt.receiptStoragePaths() as? [String] {
			helperManager.removeFiles(for: Set(p)) { success in
				if success {
					normalPackages.removeAll { $0 == receipt }
					hiddenPackages.removeAll { $0 == receipt }
					selectedPackage = nil
				}
				completion(success)
			}
		} else {
			completion(false)
		}
	}
}
