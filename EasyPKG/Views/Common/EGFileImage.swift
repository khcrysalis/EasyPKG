//
//  PackageImage.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

struct EGFileImage: View {
	var path: String?
	var size: CGFloat = 32
	
	var body: some View {
		Group {
			if let path = path, !path.isEmpty {
				Image(nsImage: NSWorkspace.shared.icon(forFile: path)).resizable()
			} else {
				Image(nsImage: NSImage(contentsOfFile: "/System/Library/CoreServices/Installer.app/Contents/Resources/package.icns")!)
					.resizable()
			}
		}
		.frame(width: size, height: size)
	}
}
