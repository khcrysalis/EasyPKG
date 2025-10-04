//
//  EPKGF.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

// MARK: - EGUtils
struct EGUtils {
//	static func readBom(atPath path: String) -> PKBOM {
//		PKBOM(bomPath: path)
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
//	}
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
		"com.apple.pkg.MobileDeviceDevelopment",
		"com.apple.pkg.CoreTypes"
	]}
}

extension EGUtils {
	static func getMacOSVersion() -> String {
		let osVersion = ProcessInfo.processInfo.operatingSystemVersion
		return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
	}
}
