//
//  HelperToolProtocol.swift
//  EasyPKG
//
//  Created by samsam on 9/16/25.
//

import ServiceManagement

// MARK: - HelperManager (extension): Actions
extension EGHelperManager {
	enum EGHelperAction {
		case none
		case install
		case uninstall
	}
}

// MARK: - HelperManager
@MainActor class EGHelperManager: ObservableObject {
	@Published var isHelperToolInstalled: Bool = false
	@Published var message: String = "Checking..."
	
	private var _helperConnection: NSXPCConnection?
	let helperToolIdentifier = "thewonderofyou.EasyPKG.Helper"
	
	var status: String {
		isHelperToolInstalled 
		? "Registered" 
		: "Not Registered"
	}

	init() {
		Task {
			await manageHelperTool()
		}
	}

	func manageHelperTool(action: EGHelperAction = .none) async {
		let plistName = "\(helperToolIdentifier).plist"
		let service = SMAppService.daemon(plistName: plistName)
		var occurredError: NSError?
		
		switch action {
		case .install:
			switch service.status {
			case .requiresApproval:
				message = "Registered but requires enabling in System Settings > Login Items."
				SMAppService.openSystemSettingsLoginItems()
			case .enabled:
				message = "Service is already enabled."
			default:
				do {
					try service.register()
					if service.status == .requiresApproval {
						SMAppService.openSystemSettingsLoginItems()
					}
				} catch let nsError as NSError {
					occurredError = nsError
					if nsError.code == 1 {
						message = "Permission required. Enable in System Settings > Login Items."
						SMAppService.openSystemSettingsLoginItems()
					} else {
						message = "Installation failed: \(nsError.localizedDescription)"
						print("Failed to register helper: \(nsError.localizedDescription)")
					}
					
				}
			}
			
		case .uninstall:
			do {
				try await service.unregister()
				_helperConnection?.invalidate()
				_helperConnection = nil
			} catch let nsError as NSError {
				occurredError = nsError
				print("Failed to unregister helper: \(nsError.localizedDescription)")
			}
			
		case .none:
			break
		}
		
		updateStatusMessages(with: service, occurredError: occurredError)
		isHelperToolInstalled = (service.status == .enabled)
	}
	
	private func _getConnection() -> NSXPCConnection? {
		if let connection = _helperConnection {
			return connection
		}
		let connection = NSXPCConnection(machServiceName: helperToolIdentifier, options: .privileged)
		connection.remoteObjectInterface = NSXPCInterface(with: EGHelperProtocol.self)
		connection.invalidationHandler = { [weak self] in
			self?._helperConnection = nil
		}
		connection.resume()
		_helperConnection = connection
		return connection
	}
	
	func updateStatusMessages(with service: SMAppService, occurredError: NSError?) {
		if let nsError = occurredError {
			switch nsError.code {
			case kSMErrorAlreadyRegistered:
				message = "Service is already registered and enabled."
			case kSMErrorLaunchDeniedByUser:
				message = "User denied permission. Enable in System Settings > Login Items."
			case kSMErrorInvalidSignature:
				message = "Invalid signature, ensure proper signing on the application and helper tool."
			case 1:
				message = "Authorization required in Settings > Login Items."
			default:
				message = "Operation failed: \(nsError.localizedDescription)"
			}
		} else {
			switch service.status {
			case .notRegistered:
				message = "Service hasn’t been registered. You may register it now."
			case .enabled:
				message = "Service successfully registered and eligible to run."
			case .requiresApproval:
				message = "Service registered but requires user approval in Settings > Login Items."
			case .notFound:
				message = "Service is not installed."
			@unknown default:
				message = "Unknown service status (\(service.status))."
			}
		}
	}
}

// MARK: - HelperManager (extension): Helper Protocol
extension EGHelperManager: @preconcurrency EGHelperProtocol {
	func removeFiles(for relativePaths: Set<String>, reply: @escaping (Bool) -> Void) {
		guard
			isHelperToolInstalled,
			let connection = _getConnection(),
			let proxy = connection.remoteObjectProxyWithErrorHandler({ error in
				print("XPC error: \(error)")
				reply(false)
			}) as? EGHelperProtocol
		else {
			reply(false)
			return
		}

		proxy.removeFiles(for: relativePaths, reply: reply)
	}
}
