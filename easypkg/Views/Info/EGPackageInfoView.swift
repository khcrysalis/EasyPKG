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
	@State private var shouldShowWarning: Bool = false
	
	var body: some View {
		VStack {
			VStack(alignment: .leading) {
				HStack {
					EGFileImage()
					Text(receipt._packageName() as? String ?? "Unknown")
						.font(.largeTitle)
						.frame(maxWidth: .infinity, alignment: .leading)
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
	}
	
	// MARK: Load
	
	private func loadData() {
		
		print(receipt.receiptStoragePaths())
		print(type(of: receipt.receiptStoragePaths()))
		
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
}
