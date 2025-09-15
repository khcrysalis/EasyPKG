//
//  EGSettingsView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - EGSettingsView
struct EGSettingsView: View {
	@AppStorage("epkg.defaultVolume") var defaultVolume: String = "/"
	@AppStorage("epkg.showHiddenPackages") var showHiddenPackages: Bool = false
	
	@State private var volumes: [String] = []
	
	// MARK: Body
	
	var body: some View {
		Form {
			Section {
				Toggle("Show Hidden Packages", isOn: $showHiddenPackages)
			}
			
			Section {
				Picker("Default Volume", selection: $defaultVolume) {
					ForEach(volumes, id: \.self) { volume in
						Text(volume).tag(volume)
					}
				}
				
				Button("Reset to Defaults") {
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
