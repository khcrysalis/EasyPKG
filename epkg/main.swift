//
//  main.swift
//  epkg
//
//  Created by samsam on 9/9/25.
//

import Foundation

// PKPackageInfo(identifier: "com.apple.pkg.SFSymbols")
// PKDistribution(contentsOfURL: URL(fileURLWithPath: "/"), error: nil)

// we can specify the history with a string to the volume, for example "/" or "/Volumes/<name>"
if let history = PKInstallHistory.history(onVolume: "/Volumes/Raccoon") as? AnyObject {
	if let installedItems = history.installedItems() as? Array<NSDictionary> {
		print(installedItems)
	}
}

// The default history is on your root volume
if let history = PKInstallHistory.defaultHistory() as? AnyObject {
	if let installedItems = history.installedItems() as? Array<NSDictionary> {
		print(installedItems)
	}
}

let rootVolume: String = "/"

if let receipts = PKReceipt.receiptsOnVolume(atPath: rootVolume) as? [PKReceipt] {
	for receipt in receipts {
		// print(receipt.receiptStoragePaths() ?? "") // Optional<Any>
		// print(receipt.packageVersion()) // Optional(Int)
		// print(receipt.packageGroups()) // Optional<Any>
		// print(receipt.additionalInfo()) Optional(NSDictionary)
		
		let prefixPath = receipt.installPrefixPath() as? String ?? ""
		let normalizedPrefix = prefixPath.hasPrefix("/")
			? prefixPath
			: rootVolume + prefixPath
		let separator = normalizedPrefix.hasSuffix("/") ? "" : "/"

		print("Identifier: \(receipt.packageIdentifier()!)")
		print("VolumePath: \(rootVolume)")
		print("PrefixPath: \(normalizedPrefix)")
		print("Paths:")
		if let enumerator = receipt._directoryEnumerator() as? NSEnumerator {
			while let path = enumerator.nextObject() as? String {
				print("| " + normalizedPrefix + separator + path)
			}
		}
		print("v\n\n\n\n")
	}
}

// PKReceipt.receipt(withIdentifier: <#T##Any!#>, volume: <#T##Any!#>)

if let bom = PKBOM(bomPath: "/private/var/db/receipts/com.geode-sdk.geode.bom") {
	print("Total size: \(bom.totalSize())")
	print("File count: \(bom.fileCount())")

	if let enumerator = bom.directoryEnumerator() as? NSEnumerator {
		while let path = enumerator.nextObject() as? String {
//			if let attrs = bom.attributesOfItem(atPath: path) as? [String: Any] {
//				print("Path: \(path)")
//				print("  Attributes: \(attrs)")
//			}
			print(path)
		}
	}
}

//let a = PKComponent.findComponents(withIdentifier: "com.apple.pkg.SFSymbols", destination: "/")
//print(a)

// we need a way to find a package based on the identifier somehow
