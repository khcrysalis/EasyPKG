//
//  easypkgApp.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI
#if !DEBUG
import Sparkle
#endif

// MARK: - easypkgApp
@main struct Entry: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate	
	
	var body: some Scene {
		WindowGroup {
			EGPackageListView()
		}
		.commands {
			#if !DEBUG
			CommandGroup(after: .appInfo) {
				GBCheckForUpdatesButton(updater: AppDelegate.updaterController.updater)
			}
			#endif
		}
		Settings {
			EGSettingsView().frame(width: 450, height: 500)
		}
	}
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {
	func applicationShouldTerminateAfterLastWindowClosed(
		_ sender: NSApplication
	) -> Bool {
		true
	}
	
	#if !DEBUG
	static let updaterController: SPUStandardUpdaterController = {
		SPUStandardUpdaterController(
			startingUpdater: true, 
			updaterDelegate: nil, 
			userDriverDelegate: nil
		)
	}()
	#endif
}
