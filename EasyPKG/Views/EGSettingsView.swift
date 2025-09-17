//
//  EGSettingsView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI
import ServiceManagement

// MARK: - EGSettingsView
struct EGSettingsView: View {
	@ObservedObject private var helperToolManager = EGHelperManager()
	@AppStorage("epkg.defaultVolume") var defaultVolume: String = "/"
	@AppStorage("epkg.showHiddenPackages") var showHiddenPackages: Bool = false
	
	@State private var volumes: [String] = []
	
	// MARK: Body
	
	var body: some View {
		Form {
			Section(.localized("Helper")) {
				LabeledContent(.localized("Status"), value: helperToolManager.status)
				HStack {
					Button(.localized("Open Settings...")) {
						SMAppService.openSystemSettingsLoginItems()
					}
					
					Spacer()
					
					if !helperToolManager.isHelperToolInstalled {
						Button(.localized("Register")) {
							Task {
								await helperToolManager.manageHelperTool(action: .install)
							}
						}
					} else {
						Button(.localized("Unregister")) {
							Task {
								await helperToolManager.manageHelperTool(action: .uninstall)
							}
						}
					}
				}
			}
			
			Section(.localized("General")) {
				Toggle(.localized("Show Hidden Packages"), isOn: $showHiddenPackages)
			}
			
			Section(.localized("Listings")) {
				Picker(.localized("Default Volume"), selection: $defaultVolume) {
					ForEach(volumes, id: \.self) { volume in
						Text(volume).tag(volume)
					}
				}
				
				Button(.localized("Reset to Defaults")) {
					showHiddenPackages = false
					defaultVolume = "/"
				}
			}
		}
		.formStyle(.grouped)
		.onAppear(perform: loadVolumes)
	}
	
	// MARK: Load
	
	private func loadVolumes() {
		let fileManager = FileManager.default
		let keys: [URLResourceKey] = [.volumeNameKey]
		if let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) {
			volumes = urls.compactMap { $0.path }
			if !volumes.contains(defaultVolume) {
				defaultVolume = volumes.first ?? "/"
			}
		}
	}
}
