//
//  HelperProtocol.swift
//  EasyPKG
//
//  Created by samsam on 9/16/25.
//

import Foundation

@objc(EGHelperProtocol)
public protocol EGHelperProtocol {
	func removeFiles(for relativePaths: Set<String>, reply: @escaping (Bool) -> Void)
}
