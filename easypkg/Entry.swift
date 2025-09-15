//
//  easypkgApp.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - easypkgApp
@main struct Entry: App {
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	
	var body: some Scene {
		WindowGroup {
			EGPackageListView()
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
}
