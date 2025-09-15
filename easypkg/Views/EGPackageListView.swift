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
	
	@State private var normalPackages: [PKReceipt] = []
	@State private var hiddenPackages: [PKReceipt] = []
	
	@State private var selectedPackage: PKReceipt? = nil
	@State private var isHistoryPresenting: Bool = false
	
	// MARK: Body
	
	var body: some View {
		NavigationSplitView {
			List(selection: $selectedPackage) {
				// Normal Packages
				Section("Installed Packages") {
					ForEach(normalPackages, id: \.self) { receipt in
						NavigationLink(value: receipt) {
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
				}

				if showHiddenPackages {
					Section("Hidden Installed Packages") {
						ForEach(hiddenPackages, id: \.self) { receipt in
							NavigationLink(value: receipt) {
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
					}
				}
			}
			.navigationTitle("Packages")
			.listStyle(.sidebar)
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
		} detail: {
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
	
	func getMacOSVersion() -> String {
		let osVersion = ProcessInfo.processInfo.operatingSystemVersion
		return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
	}
	
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
}
