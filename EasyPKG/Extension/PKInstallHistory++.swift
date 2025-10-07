//
//  PKInstallHistory++.swift
//  EasyPKG
//
//  Created by samsam on 10/4/25.
//

// MARK: - Convenience wrappers for PKInstallHistory
extension PKInstallHistory {
	static func getHistory(onVolume: String) -> Self {
		PKInstallHistory.history(onVolume: onVolume) as! Self
	}
	
	var installedItems: [NSDictionary] {
		self.installedItems() as? [NSDictionary] ?? []
	}
}
