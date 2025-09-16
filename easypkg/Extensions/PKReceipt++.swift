//
//  PKReceipt++.swift
//  easypkg
//
//  Created by samsam on 9/15/25.
//

// $(EXECUTABLE_NAME)
// MARK: - PKReceipt
extension PKReceipt {
	static func forgetReceipt(using identifier: String, volume: String) throws {
		if let r = Self.receipt(withIdentifier: identifier, volume: volume) as? PKReceipt {
			try Self.forgetReceipt(receipt: r)
		}
	}
	
	static func forgetReceipt(receipt: PKReceipt) throws {
		try receipt.forgetReceipt()
	}
	
	func forgetReceipt() throws {
		for p in self.receiptStoragePaths() as! [String] {
			try FileManager.default.removeItem(atPath: p)
		}
	}
}
