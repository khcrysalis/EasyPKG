//
//  EGPackageDescriptiveInfoView.swift
//  easypkg
//
//  Created by samsam on 9/15/25.
//


import SwiftUI

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
						"Secure",
						value: "\(receipt._isSecure())"
					)
					LabeledContent(
						"Installed Date",
						value: "\(receipt.installDate() as? Date ?? Date())"
					)
				}
				
				Section("Additional Info") {
					LabeledContent(
						"Additional Info",
						value: receipt.additionalInfo() as? String ?? "N/A"
					)
					.labelsHidden()
				}
				
				Section("Groups") {
					LabeledContent(
						"Groups",
						value: (receipt.packageGroups() as? [String])?.joined(separator: "\n") ?? "N/A"
					)
					.labelsHidden()
				}
				
				Section("Paths") {
					LabeledContent(
						"Receipt Paths",
						value: (receipt.receiptStoragePaths() as! [String]).joined(separator: "\n")
					)
					Button("Reveal in Finder") {
						let fileUrls = (receipt.receiptStoragePaths() as! [String]).map { URL(fileURLWithPath: $0) }
						NSWorkspace.shared.activateFileViewerSelecting(fileUrls)
					}
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
