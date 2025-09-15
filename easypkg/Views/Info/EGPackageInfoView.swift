//
//  PackageInfoView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageInfoView
struct EGPackageInfoView: View {
	var receipt: PKReceipt
	var volume: String
	
	@State private var prefixPath: String = ""
	@State private var prefixSeperator: String = ""
	@State private var receiptInstallPaths: [String] = []
	@State private var selectedPaths: Set<String> = []
	@State private var expandedNodes: Set<UUID> = []
	@State private var isDescriptivePresenting: Bool = false
	
	
	var body: some View {
		VStack {
			VStack(alignment: .leading) {
				HStack {
					EGFileImage()
					Text(receipt._packageName() as? String ?? "Unknown")
						.font(.largeTitle)
						.frame(maxWidth: .infinity, alignment: .leading)
					Spacer()
					Button("?") {
						isDescriptivePresenting = true
					}
				}
				Group {
					Text("\(receipt.packageVersion()! as! String) • \(receipt.packageIdentifier()! as! String)")
					Text("Installed at: \(prefixPath)")
				}
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			
			List {
				EGPackagePathsDisclosureView(
					node: EGPathNode.buildPathTree(from: receiptInstallPaths),
					selectedPaths: $selectedPaths,
					expandedNodes: $expandedNodes
				)
				.padding(.leading, 1)
			}
			.listStyle(.bordered)
			.padding(.vertical, 6)
			
			// reciept storage paths
			// package groups
			
			HStack {
				Button("Deselect All") {
					selectedPaths = []
				}
				
				Spacer()
				
				Button("Delete Selected Paths") {
					
				}
				
				Button("Delete Selected Paths & Forget") {
					
				}
				
				Button("Forget") {
					
				}
			}
		}
		.padding()
		.onAppear(perform: loadData)
		.onChange(of: selectedPaths) { oldValue, newValue in
			dump(selectedPaths)
		}
		.sheet(isPresented: $isDescriptivePresenting) {
			EGPackageDescriptiveInfoView(receipt: receipt, volume: volume)
		}
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
		
		print(receipt.installDate())
	}
}

// MARK: - EGPackageDescriptiveInfoView
struct EGPackageDescriptiveInfoView: View {
	@Environment(\.dismiss) private var dismiss
	
	var receipt: PKReceipt
	var volume: String
	
	var body: some View {
		NavigationStack {
			Form {
				Section {
					LabeledContent(
						"Name",
						value: receipt._packageName() as? String ?? "Unknown"
					)
					LabeledContent(
						"Identifier",
						value: (receipt.packageIdentifier() as! String)
					)
					LabeledContent(
						"Version",
						value: receipt.packageVersion() as? String ?? "Unknown"
					)
					LabeledContent(
						"Prefix Path",
						value: receipt.installPrefixPath() as? String ?? "Unknown"
					)
					LabeledContent(
						"Volume",
						value: volume
					)
					LabeledContent(
						"isSecure",
						value: "\(receipt._isSecure())"
					)
					LabeledContent(
						"Installed Date",
						value: receipt.installDate() as? String ?? "Unknown"
					)
					LabeledContent(
						"Additional Info",
						value: receipt.additionalInfo() as? String ?? "Unknown"
					)
					LabeledContent(
						"Groups",
						value: (receipt.packageGroups() as? [String])?.joined(separator: "\n") ?? ""
					)
				}
				Section {
					LabeledContent(
						"Receipt Paths",
						value: (receipt.receiptStoragePaths() as! [String]).joined(separator: "\n")
					)
				}
			}
			.formStyle(.grouped)
			.navigationTitle(receipt._packageName() as? String ?? "Unknown")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismiss()
					} label: {
						Text("Close")
					}
				}
			}
		}
	}
}
