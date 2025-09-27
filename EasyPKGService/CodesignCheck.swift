//
//  CodesignCheck.swift
//
//  Created by Erik Berglund on 2018-10-01.
//  Copyright © 2018 Erik Berglund. All rights reserved.
//

import Foundation
import Security

let kSecCSDefaultFlags = 0

enum CodesignCheckError: Error {
	case message(String)
}

struct CodesignCheck {
	
	// MARK: - Compare Functions
	
	static func codeSigningMatches(pid: pid_t) throws -> Bool {
		return try self.codeSigningCertificatesForSelf() == self.codeSigningCertificates(forPID: pid)
	}
	
	// MARK: - Public Functions
	
	public static func codeSigningCertificatesForSelf() throws -> [SecCertificate] {
		guard let secStaticCode = try _secStaticCodeSelf() else { return [] }
		return try _codeSigningCertificates(forStaticCode: secStaticCode)
	}
	
	public static func codeSigningCertificates(forPID pid: pid_t) throws -> [SecCertificate] {
		guard let secStaticCode = try _secStaticCode(forPID: pid) else { return [] }
		return try _codeSigningCertificates(forStaticCode: secStaticCode)
	}
	
	public static func codeSigningCertificates(forURL url: URL) throws -> [SecCertificate] {
		guard let secStaticCode = try _secStaticCode(forURL: url) else { return [] }
		return try _codeSigningCertificates(forStaticCode: secStaticCode)
	}
	
	// MARK: - Private Functions
	
	private static func _executeSecFunction(_ secFunction: () -> (OSStatus) ) throws {
		let osStatus = secFunction()
		guard osStatus == errSecSuccess else {
			throw CodesignCheckError.message(String(describing: SecCopyErrorMessageString(osStatus, nil)))
		}
	}
	
	private static func _secStaticCodeSelf() throws -> SecStaticCode? {
		var secCodeSelf: SecCode?
		try _executeSecFunction { SecCodeCopySelf(SecCSFlags(rawValue: 0), &secCodeSelf) }
		guard let secCode = secCodeSelf else {
			throw CodesignCheckError.message("SecCode returned empty from SecCodeCopySelf")
		}
		return try _secStaticCode(forSecCode: secCode)
	}
	
	private static func _secStaticCode(forPID pid: pid_t) throws -> SecStaticCode? {
		var secCodePID: SecCode?
		try _executeSecFunction { SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributePid: pid] as CFDictionary, [], &secCodePID) }
		guard let secCode = secCodePID else {
			throw CodesignCheckError.message("SecCode returned empty from SecCodeCopyGuestWithAttributes")
		}
		return try _secStaticCode(forSecCode: secCode)
	}
	
	private static func _secStaticCode(forURL url: URL) throws -> SecStaticCode? {
		var secStaticCodePath: SecStaticCode?
		try _executeSecFunction { SecStaticCodeCreateWithPath(url as CFURL, [], &secStaticCodePath) }
		guard let secStaticCode = secStaticCodePath else {
			throw CodesignCheckError.message("SecStaticCode returned empty from SecStaticCodeCreateWithPath")
		}
		return secStaticCode
	}
	
	private static func _secStaticCode(forSecCode secCode: SecCode) throws -> SecStaticCode? {
		var secStaticCodeCopy: SecStaticCode?
		try _executeSecFunction { SecCodeCopyStaticCode(secCode, [], &secStaticCodeCopy) }
		guard let secStaticCode = secStaticCodeCopy else {
			throw CodesignCheckError.message("SecStaticCode returned empty from SecCodeCopyStaticCode")
		}
		return secStaticCode
	}
	
	private static func _isValid(secStaticCode: SecStaticCode) throws {
		try _executeSecFunction { SecStaticCodeCheckValidity(secStaticCode, SecCSFlags(rawValue: kSecCSDoNotValidateResources | kSecCSCheckNestedCode), nil) }
	}
	
	private static func _secCodeInfo(forStaticCode secStaticCode: SecStaticCode) throws -> [String: Any]? {
		try _isValid(secStaticCode: secStaticCode)
		var secCodeInfoCFDict:  CFDictionary?
		try _executeSecFunction { SecCodeCopySigningInformation(secStaticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &secCodeInfoCFDict) }
		guard let secCodeInfo = secCodeInfoCFDict as? [String: Any] else {
			throw CodesignCheckError.message("CFDictionary returned empty from SecCodeCopySigningInformation")
		}
		return secCodeInfo
	}
	
	private static func _codeSigningCertificates(forStaticCode secStaticCode: SecStaticCode) throws -> [SecCertificate] {
		guard
			let secCodeInfo = try _secCodeInfo(forStaticCode: secStaticCode),
			let secCertificates = secCodeInfo[kSecCodeInfoCertificates as String] as? [SecCertificate] 
		else { 
			return [] 
		}
		return secCertificates
	}
}

