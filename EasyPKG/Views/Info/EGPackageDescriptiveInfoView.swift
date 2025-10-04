//
//  EGPackageDescriptiveInfoView.swift
//  easypkg
//
//  Created by samsam on 9/15/25.
//


import SwiftUI

// MARK: - EGPackageDescriptiveInfoView
struct EGPackageDescriptiveInfoView: View {
	@Environment(\.dismiss) private var _dismiss
	
	var receipt: PKReceipt
	var volume: String
	
	// MARK: Body
	
	var body: some View {
		NavigationStack {
			Form {
				Section {
					LabeledContent(
						.localized("Name"),
						value: receipt.packageName
					)
					LabeledContent(
						.localized("Identifier"),
						value: receipt.packageIdentifier
					)
					LabeledContent(
						.localized("Version"),
						value: receipt.packageVersion
					)
					LabeledContent(
						.localized("Install Path"),
						value: receipt.packageInstallPath
					)
					LabeledContent(
						.localized("Volume"),
						value: volume
					)
					LabeledContent(
						.localized("Secure"),
						value: "\(receipt._isSecure())"
					)
					LabeledContent(
						.localized("Installed Date"),
						value: "\(receipt.installDate)"
					)
				}
				
				Section(.localized("Groups")) {
					LabeledContent(
						.localized("Groups"),
						value: (receipt.packageGroups?.joined(separator: "\n") ?? .localized("Unknown"))
					)
					.labelsHidden()
				}
				
				Section(.localized("Receipt Paths")) {
					LabeledContent(
						.localized("Receipt Paths"),
						value: (receipt.receiptStoragePaths).joined(separator: "\n")
					)
					Button(.localized("Reveal in Finder")) {
						let fileUrls = (receipt.receiptStoragePaths).map { URL(fileURLWithPath: $0) }
						NSWorkspace.shared.activateFileViewerSelecting(fileUrls)
					}
				}
			}
			.formStyle(.grouped)
			.navigationTitle(receipt.packageName)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						_dismiss()
					} label: {
						Text(.localized("Close"))
					}
				}
			}
		}
	}
}
