//
//  PackageInfoView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - PackageInfoView
struct EGPackageInfoView: View {
	@AppStorage("epkg.defaultVolume") var defaultVolume: String = "/"
	
	@State private var prefixPath: String = ""
	@State private var prefixSeperator: String = ""
	@State private var receiptInstallPaths: [String] = []
	@State private var selectedPaths: Set<String> = []
	@State private var expandedNodes: Set<UUID> = []
	@State private var isDescriptivePresenting: Bool = false
	@State private var filePathsView: AnyView? = nil
	@State private var isAlertPresenting = false
	@State private var alertTitle = ""
	@State private var alertMessage = ""
	
	var receipt: PKReceipt
	var volume: String
	
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
					Text("Installed on \(receipt.installDate()! as! Date)")
					Text("Unpackaged at \(prefixPath)")
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
					Button("Deselect All") {
						selectedPaths = []
					}
					
					Spacer()
					
					Button("Delete Selected Paths") {
						do {
							try deleteFiles(for: selectedPaths)
						} catch {
							alertTitle = "Failed to delete \(receipt._packageName() as? String ?? "Unknown")"
							alertMessage = error.localizedDescription
							isAlertPresenting = true
						}
					}
					
					Button("Delete Selected Paths & Forget") {
						do {
							try deleteFiles(for: selectedPaths)
							try receipt.forgetReceipt()
						} catch {
							alertTitle = "Failed to delete & forget \(receipt._packageName() as? String ?? "Unknown")"
							alertMessage = error.localizedDescription
							isAlertPresenting = true
						}
					}
				}
				.disabled(selectedPaths.isEmpty)
				
				Button("Forget") {
					do {
						try receipt.forgetReceipt()
					} catch {
						alertTitle = "Failed to forget \(receipt._packageName() as? String ?? "Unknown")"
						alertMessage = error.localizedDescription
						isAlertPresenting = true
					}
				}
			}
		}
		.padding(4)
		.onAppear {
			loadData()
			updatePaths()
		}
		.onChange(of: selectedPaths) { oldValue, newValue in
			dump(selectedPaths)
		}
		.sheet(isPresented: $isDescriptivePresenting) {
			EGPackageDescriptiveInfoView(receipt: receipt, volume: volume)
		}
		.alert(alertTitle, isPresented: $isAlertPresenting, actions: {
			Button("OK", role: .cancel) { }
		}, message: {
			Text(alertMessage)
		})
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
	
	// MARK: Helpers
	
	private func deleteFiles(for relativePaths: Set<String>) throws {
		let sortedPaths = relativePaths.sorted {
			$0.components(separatedBy: "/").count >
			$1.components(separatedBy: "/").count
		}
		
		for path in sortedPaths {
			try FileManager.default.removeItem(atPath: path)
		}
	}
}
