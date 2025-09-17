//
//  PackageInfoView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageInfoView
struct EGPackageInfoView: View {
	@State private var prefixPath: String = ""
	@State private var prefixSeperator: String = ""
	@State private var receiptInstallPaths: [String] = []
	@State private var selectedPaths: Set<String> = []
	@State private var expandedNodes: Set<UUID> = []
	@State private var isDescriptivePresenting: Bool = false
	@State private var filePathsView: AnyView? = nil
	
	@State private var isDeleteAlertPresenting = false
	@State private var isForgetDeleteAlertPresenting = false
	@State private var isForgetAlertPresenting = false
	@State private var isAlertPresenting = false
	@State private var alertTitle = ""
	
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
						isDescriptivePresenting = true
					}
				}
				Group {
					Text(verbatim: "\(receipt.packageVersion()! as! String) • \(receipt.packageIdentifier()! as! String)")
					Text(verbatim: .localized("Installed on %@", arguments: (receipt.installDate() as! Date).description))
					Text(.localized("Unpackaged at %@", prefixPath))
				}
				.font(.subheadline)
				.textSelection(.enabled)
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			Group {
				ZStack {
					if let pathsView = filePathsView {
						pathsView.opacity(filePathsView == nil ? 0 : 1)
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
						selectedPaths = []
					}
					
					Spacer()
					
					Button(.localized("Delete Selected Paths")) {
						isDeleteAlertPresenting = true
					}
					
					Button(.localized("Delete Selected Paths & Forget")) {
						isForgetDeleteAlertPresenting = true
					}
				}
				.disabled(selectedPaths.isEmpty)
				
				Button(.localized("Forget")) {
					isForgetAlertPresenting = true
				}
			}
		}
		.padding(4)
		.onAppear {
			loadData()
			updatePaths()
		}
		.sheet(isPresented: $isDescriptivePresenting) {
			EGPackageDescriptiveInfoView(receipt: receipt, volume: volume)
		}
		.alert(alertTitle, isPresented: $isAlertPresenting, actions: {
			Button("OK", role: .cancel) { }
		})
		.alert(.localized("Are you sure you want to delete the selected files?"), isPresented: $isDeleteAlertPresenting) {
			Button(.localized("Delete Selected Paths"), role: .destructive) {
				helperManager.removeFiles(for: selectedPaths) { success in
					if !success {
						alertTitle = "Failed to delete \(receipt._packageName() as? String ?? .localized("Unknown"))"
						isAlertPresenting = true
					} else {
						selectedPaths = []
					}
				}
			}
			Button(.localized("Cancel"), role: .cancel) { }
		}
		.alert(.localized("Are you sure you want to forget this package and delete selected files?"), isPresented: $isForgetDeleteAlertPresenting) {
			Button(.localized("Delete Selected Paths & Forget"), role: .destructive) {
				helperManager.removeFiles(for: selectedPaths) { success in
					if !success {
						alertTitle = "Failed to delete & forget \(receipt._packageName() as? String ?? .localized("Unknown"))"
						isAlertPresenting = true
					} else {
						selectedPaths = []
						forget(for: receipt) { success in
							if !success {
								alertTitle = "Failed to forget \(receipt._packageName() as? String ?? .localized("Unknown"))"
								isAlertPresenting = true
							}
						}
					}
				}
			}
			Button(.localized("Cancel"), role: .cancel) { }
		}
		.alert(.localized("Are you sure you want to forget this package?"), isPresented: $isForgetAlertPresenting) {
			Button(.localized("Forget"), role: .destructive) {
				forget(for: receipt) { success in
					if !success {
						alertTitle = "Failed to forget \(receipt._packageName() as? String ?? .localized("Unknown"))"
						isAlertPresenting = true
					}
				}
			}
			Button(.localized("Cancel"), role: .cancel) { }
		}
		.padding()
	}
	
	// MARK: Load
	
	private func loadData() {
		let prefix = receipt.installPrefixPath()! as! String
		prefixPath = prefix.hasPrefix("/") ? prefix : volume + prefix
		prefixSeperator = prefixPath.hasSuffix("/") ? "" : "/"
		
		if let enumerator = receipt._directoryEnumerator() as? NSEnumerator {
			EGUtils.listPathsFromDirectoryEnumerator(
				enumerator: enumerator,
				prefix: prefixPath + prefixSeperator,
				installPaths: &receiptInstallPaths
			)
		}
	}
	
	private func updatePaths() {
		self.filePathsView = nil
		
		DispatchQueue.global().async {
			let paths = createChartView()
			
			DispatchQueue.main.async {
				withAnimation(.easeIn(duration: 0.3)) {
					self.filePathsView = paths
				}
			}
		}
	}
	
	private func createChartView() -> AnyView {
		AnyView(
			List {
				EGPackagePathsDisclosureView(
					node: EGPathNode.buildPathTree(from: receiptInstallPaths),
					selectedPaths: $selectedPaths,
					expandedNodes: $expandedNodes
				)
				.padding(.leading, 1)
			}
		)
	}
	
	private func forget(for receipt: PKReceipt, completion: @escaping (Bool) -> Void) {
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
