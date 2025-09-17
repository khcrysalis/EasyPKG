//
//  EPKGF.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

struct EGUtils {
	static func receiptsOnVolume(atPath path: String) -> [PKReceipt] {
		(PKReceipt.receiptsOnVolume(atPath: path) as? [PKReceipt]) ?? []
	}

	static func receiptHistoryOnVolume(atPath path: String) -> [HistoryItem] {
		var items: [HistoryItem] = []
		
		if
			let history = PKInstallHistory.history(onVolume: path) as? AnyObject,
			let installedItems = history.installedItems() as? [NSDictionary]
		{
			for dict in installedItems {
				if let date = dict["date"] as? Date {
					let displayName = dict["displayName"] as? String ?? ""
					let displayVersion = dict["displayVersion"] as? String ?? ""
					let processName = dict["processName"] as? String ?? ""
					
					items.append(HistoryItem(
						date: date,
						displayName: displayName,
						displayVersion: displayVersion,
						processName: processName
					))
				}
			}
		}
		
		return items.sorted { $0.date > $1.date }
	}
	
	static func readBom(atPath path: String) -> PKBOM {
		PKBOM(bomPath: path)
//		if let bom = PKBOM(bomPath: "/private/var/db/receipts/com.geode-sdk.geode.bom") {
//			print("Total size: \(bom.totalSize())")
//			print("File count: \(bom.fileCount())")
//
//			if let enumerator = bom.directoryEnumerator() as? NSEnumerator {
//				while let path = enumerator.nextObject() as? String {
//		//			if let attrs = bom.attributesOfItem(atPath: path) as? [String: Any] {
//		//				print("Path: \(path)")
//		//				print("  Attributes: \(attrs)")
//		//			}
//					print(path)
//				}
//			}
//		}
	}
	
	static func listPathsFromDirectoryEnumerator(
		enumerator: NSEnumerator,
		prefix: String = "",
		installPaths: inout [String]
	) {
		var paths: [String] = []
		
		while let path = enumerator.nextObject() as? String {
			paths.append(prefix + path)
		}
		
		installPaths = paths
	}
}

extension EGUtils {
	static func hiddenPackageIdentifiers() -> [String] {[
		"com.apple.files.data-template",
		"com.apple.pkg.XProtectPlistConfigData",
		"com.apple.pkg.XProtectPayloads",
		"com.apple.pkg.MRTConfigData",
		"com.apple.pkg.RosettaUpdateAuto",
		"com.apple.pkg.GatekeeperCompatibilityData",
		"com.apple.pkg.CLTools",
		"com.apple.pkg.XcodeSystemResources",
		"com.apple.pkg.MobileDeviceDevelopment"
	]}
}

extension EGUtils {
	struct HistoryItem: Identifiable {
		let id = UUID() // unique identifier
		let date: Date
		let displayName: String
		let displayVersion: String
		let processName: String
	}
}

/*

 //
 //  main.swift
 //  epkg
 //
 //  Created by samsam on 9/9/25.
 //

 import Foundation

 // PKPackageInfo(identifier: "com.apple.pkg.SFSymbols")
 // PKDistribution(contentsOfURL: URL(fileURLWithPath: "/"), error: nil)

 // PKReceipt.receipt(withIdentifier: <#T##Any!#>, volume: <#T##Any!#>)
 //let a = PKComponent.findComponents(withIdentifier: "com.apple.pkg.SFSymbols", destination: "/")
 //print(a)

 // we need a way to find a package based on the identifier somehow

 */

