//
//  EGSettingsView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI
import ServiceManagement
#if !DEBUG
import Sparkle
#endif

#if !DEBUG
// MARK: - EGCheckForUpdatesViewModel
final class EGCheckForUpdatesViewModel: ObservableObject {
	@Published var canCheckForUpdates = false

	init(updater: SPUUpdater) {
		updater.publisher(for: \.canCheckForUpdates).assign(to: &$canCheckForUpdates)
	}
}

struct GBCheckForUpdatesButton: View {
	@ObservedObject private var _checkForUpdatesViewModel: EGCheckForUpdatesViewModel
	private let _updater: SPUUpdater

	init(updater: SPUUpdater) {
		self._updater = updater
		self._checkForUpdatesViewModel = EGCheckForUpdatesViewModel(updater: updater)
	}

	var body: some View {
		Button(.localized("Check for Updates..."), action: _updater.checkForUpdates)
			.disabled(!_checkForUpdatesViewModel.canCheckForUpdates)
	}
}
#endif

// MARK: - EGSettingsView
struct EGSettingsView: View {
	@ObservedObject private var _helperToolManager = EGHelperManager()
	@AppStorage("epkg.defaultVolume") private var _defaultVolume: String = "/"
	@AppStorage("epkg.showHiddenPackages") private var _showHiddenPackages: Bool = false
	
	@State private var _volumes: [String] = []
	
	var body: some View {
		Form {
			#if !DEBUG
			Section {
				GBCheckForUpdatesButton(updater: AppDelegate.updaterController.updater)
			}
			#endif
			
			Section(.localized("Helper")) {
				LabeledContent(.localized("Status"), value: _helperToolManager.status)
				HStack {
					Button(.localized("Open Settings...")) {
						SMAppService.openSystemSettingsLoginItems()
					}
					
					Spacer()
					
					if !_helperToolManager.isHelperToolInstalled {
						Button(.localized("Register")) {
							Task {
								await _helperToolManager.manageHelperTool(action: .install)
							}
						}
					} else {
						Button(.localized("Unregister")) {
							Task {
								await _helperToolManager.manageHelperTool(action: .uninstall)
							}
						}
					}
				}
			}
			
			Section(.localized("General")) {
				Toggle(.localized("Show Hidden Packages"), isOn: $_showHiddenPackages)
			}
			
			Section(.localized("Listings")) {
				Picker(.localized("Default Volume"), selection: $_defaultVolume) {
					ForEach(_volumes, id: \.self) { volume in
						Text(volume).tag(volume)
					}
				}
				
				Button(.localized("Reset to Defaults")) {
					_showHiddenPackages = false
					_defaultVolume = "/"
				}
			}
		}
		.formStyle(.grouped)
		.onAppear(perform: _loadVolumes)
	}
	
	// MARK: Load
	
	private func _loadVolumes() {
		let fileManager = FileManager.default
		let keys: [URLResourceKey] = [.volumeNameKey]
		if let urls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: []) {
			_volumes = urls.compactMap { $0.path }
			if !_volumes.contains(_defaultVolume) {
				_defaultVolume = _volumes.first ?? "/"
			}
		}
	}
}
