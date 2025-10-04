//
//  NSAlert++.swift
//  EasyPKG
//
//  Created by samsam on 10/3/25.
//

import Cocoa

// MARK: - NSAlert (extension): present
extension NSAlert {
	static func present(
		title: String,
		message: String? = nil,
		style: NSAlert.Style = .informational,
		cancelButtonTitle: String = .localized("Cancel"),
		primaryButton: (title: String, isDestructive: Bool)? = nil,
		completion: (() -> Void)? = nil
	) {
		DispatchQueue.main.async {
			let alert = NSAlert()
			alert.messageText = title
			alert.informativeText = message ?? ""
			alert.alertStyle = style
			
			if let primary = primaryButton {
				let btn = alert.addButton(withTitle: primary.title)
				if primary.isDestructive {
					btn.bezelColor = .systemRed
				}
			}
			
			alert.addButton(withTitle: cancelButtonTitle)
			
			if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.mainWindow {
				alert.beginSheetModal(for: window) { response in
					let firstButtonIndex = NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
					let index = response.rawValue - firstButtonIndex
					if primaryButton != nil && index == 0 {
						completion?()
					}
				}
			} else {
				let response = alert.runModal()
				let index = response.rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
				if primaryButton != nil && index == 0 {
					completion?()
				}
			}
		}
	}
}
