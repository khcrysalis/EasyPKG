//
//  Entry.swift
//  EasyPKG
//
//  Created by samsam on 9/16/25.
//

import Foundation

// MARK: - Entry
@main struct Entry {
	static func main() {
		let delegate = HelperToolDelegate()
		let listener = NSXPCListener(machServiceName: "thewonderofyou.EasyPKG.Helper")
		listener.delegate = delegate
		listener.resume()
		RunLoop.main.run()
	}
}

// MARK: - HelperToolDelegate
class HelperToolDelegate: NSObject, NSXPCListenerDelegate, EGHelperProtocol {
	func listener(
		_ listener: NSXPCListener, 
		shouldAcceptNewConnection newConnection: NSXPCConnection
	) -> Bool {
		guard 
			_isValidClient(connection: newConnection) 
		else {
			return false
		}
		
		newConnection.exportedInterface = NSXPCInterface(with: EGHelperProtocol.self)
		newConnection.exportedObject = self
		newConnection.resume()
		return true
	}

	func removeFiles(for relativePaths: Set<String>, reply: @escaping (Bool) -> Void) {
		let sortedPaths = relativePaths.sorted {
			$0.components(separatedBy: "/").count >
			$1.components(separatedBy: "/").count
		}
		
		DispatchQueue.global().async {
			do {
				for path in sortedPaths {
					try FileManager.default.removeItem(atPath: path)
				}
				reply(true)
			} catch {
				reply(false)
			}
		}
	}
	
	private func _isValidClient(connection: NSXPCConnection) -> Bool {
		do {
			return try CodesignCheck.codeSigningMatches(pid: connection.processIdentifier)
		} catch {
			return false
		}
	}
}
