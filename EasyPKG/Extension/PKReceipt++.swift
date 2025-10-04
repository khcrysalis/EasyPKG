//
//  PKReceipt++.swift
//  EasyPKG
//
//  Created by samsam on 10/3/25.
//

// MARK: - Convenience wrappers for PKReceipt
extension PKReceipt {
	var packageIdentifier: String {
		self.packageIdentifier() as! String
	}
	
	var packageVersion: String {
		self.packageVersion() as! String
	}
	
	var installDate: Date {
		self.installDate() as! Date
	}
	
	var packageName: String {
		self._packageName() as? String ?? self.packageIdentifier
	}
	
	var receiptStoragePaths: [String] {
		self.receiptStoragePaths() as! [String]
	}
	
	var packageGroups: [String]? {
		self.packageGroups() as? [String]
	}
	
	var installPrefixPath: String {
		self.installPrefixPath() as! String
	}
	
	var packageInstallPath: String {
		let volume = UserDefaults.standard.string(forKey: "epkg.defaultVolume") ?? "/"
		let prefix = installPrefixPath.hasPrefix("/") ? installPrefixPath : volume + installPrefixPath
		return prefix.hasSuffix("/") ? prefix : prefix + "/"
	}
	
	var isHidden: Bool {
		EGUtils.hiddenPackageIdentifiers().contains(where: { packageIdentifier.contains($0) })
	}
	
	static func getReceiptsOnVolume(atPath path: String) -> [PKReceipt] {
		(Self.receiptsOnVolume(atPath: path) as? [PKReceipt]) ?? []
	}
}
