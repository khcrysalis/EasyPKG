//
//  PKReceipt++.swift
//  EasyPKG
//
//  Created by samsam on 10/3/25.
//

// MARK: - Convenience wrappers for PKReceipt
extension PKReceipt {
	var packageIdentifier: String { self.packageIdentifier() as! String }
	var packageVersion: String { self.packageVersion() as? String ?? "0" }
	var packageName: String { self._packageName() as? String ?? self.packageIdentifier }
	var packageGroups: [String]? { self.packageGroups() as? [String] }
	var installDate: Date { self.installDate() as? Date ?? Date() }
	var receiptStoragePaths: [String] { self.receiptStoragePaths() as? [String] ?? [] }
	var installPrefixPath: String { self.installPrefixPath() as! String }
	
	var packageInstallPath: String {
		let volume = UserDefaults.standard.string(forKey: "epkg.defaultVolume") ?? "/"
		let prefix = installPrefixPath.hasPrefix("/") ? installPrefixPath : volume + installPrefixPath
		return prefix.hasSuffix("/") ? prefix : prefix + "/"
	}
	
	var isHidden: Bool {
		self.receiptStoragePaths.contains { $0.hasPrefix("/Library/Apple/System/Library/Receipts/") }
	}
	
	static func getReceiptsOnVolume(atPath path: String) -> [PKReceipt] {
		Self._clearCache()
		return (Self.receiptsOnVolume(atPath: path) as? [PKReceipt]) ?? []
	}
	
	func listUniqueFilesToDelete(fromVolume volume: String) -> Set<String> {
		let ourPaths = self.enumeratePaths()
		let otherPaths = Self.enumerateOtherPackagePaths(excluding: self, onVolume: volume)
		return ourPaths.subtracting(otherPaths)
	}
	
	func listUniqueFilesToExclude(fromVolume volume: String) -> Set<String> {
		let ourPaths = self.enumeratePaths()
		let otherPaths = Self.enumerateOtherPackagePaths(excluding: self, onVolume: volume)
		let sharedPaths = ourPaths.intersection(otherPaths)
		let volumeSet: Set<String> = [volume]
		return sharedPaths.union(volumeSet)
	}


	// MARK: - Path Enumeration

	func enumeratePaths() -> Set<String> {
		var paths = Set<String>()
		if let enumerator = self._directoryEnumerator() as? NSEnumerator {
			for case let file as String in enumerator {
				paths.insert(self.packageInstallPath + file)
			}
		}
		
		// lol
		var prefix = (self.packageInstallPath == UserDefaults.standard.string(forKey: "epkg.defaultVolume") ?? "/") 
		? "" 
		: self.packageInstallPath
		
		if !prefix.isEmpty {
			if prefix.hasSuffix("/") {
				prefix.removeLast()
			}
			paths.insert(prefix)
		}
		
		return paths
	}

	static func enumerateOtherPackagePaths(excluding receipt: PKReceipt, onVolume volume: String) -> Set<String> {
		var paths = Set<String>()
		let otherPackages = Self.getReceiptsOnVolume(atPath: volume).filter {
			$0.packageIdentifier != receipt.packageIdentifier
		}

		for pkg in otherPackages {
			paths.formUnion(pkg.enumeratePaths())
		}

		return paths
	}
}
