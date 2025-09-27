//
//  String+localized.swift
//  NimbleKit
//
//  Created by samara on 20.03.2025.
//

import Foundation.NSString
import SwiftUI

extension String {
	// from: https://github.com/NSAntoine/Antoine/blob/main/Antoine/Backend/Extensions/Foundation.swift#L43-L55
	// was given permission to use any code from antoine as I like - thank you Serena!~
	
	static func localized(_ name: String) -> String {
		NSLocalizedString(name, comment: "")
	}
	
	static func localized(_ name: String, arguments: CVarArg...) -> String {
		String(format: NSLocalizedString(name, comment: ""), arguments: arguments)
	}
	/// Localizes the current string using the main bundle.
	///
	/// - Returns: The localized string.
	func localized() -> String {
		String.localized(self)
	}
}

extension LocalizedStringKey {
	static func localized(_ key: String) -> LocalizedStringKey {
		LocalizedStringKey(key)
	}
	
	static func localized(_ key: String, _ arguments: CVarArg...) -> LocalizedStringKey {
		let format = NSLocalizedString(key, comment: "")
		let formatted = String(format: format, arguments: arguments)
		return LocalizedStringKey(formatted)
	}
}
