//
//  PackagePathsDisclosureView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI
import CryptoKit

// MARK: - PathNode
struct EGPathNode: Identifiable {
	let id: UUID
	let name: String
	let path: String
	var children: [EGPathNode] = []

	init(name: String, path: String, children: [EGPathNode] = []) {
		self.name = name
		self.path = path
		self.children = children
		self.id = UUID(uuidString: Self.generateUUID(from: path)) ?? UUID()
	}

	static func buildPathTree(from paths: [String]) -> EGPathNode {
		var root = EGPathNode(name: "/", path: "/")

		for path in paths {
			let components = path.split(separator: "/").map(String.init)
			insert(components, into: &root, currentPath: "")
		}

		return root
	}

	static func insert(_ components: [String], into node: inout EGPathNode, currentPath: String) {
		guard let first = components.first else { return }
		let newPath = currentPath + "/" + first

		if let index = node.children.firstIndex(where: { $0.name == first }) {
			insert(Array(components.dropFirst()), into: &node.children[index], currentPath: newPath)
		} else {
			var newChild = EGPathNode(name: first, path: newPath)
			insert(Array(components.dropFirst()), into: &newChild, currentPath: newPath)
			node.children.append(newChild)
		}
	}
	
	static func generateUUID(from string: String) -> String {
		let hash = SHA256.hash(data: Data(string.utf8))
		let uuidBytes = Array(hash.prefix(16))
		let uuid = UUID(uuid: (
			uuidBytes[0], uuidBytes[1], uuidBytes[2], uuidBytes[3],
			uuidBytes[4], uuidBytes[5], uuidBytes[6], uuidBytes[7],
			uuidBytes[8], uuidBytes[9], uuidBytes[10], uuidBytes[11],
			uuidBytes[12], uuidBytes[13], uuidBytes[14], uuidBytes[15]
		))
		return uuid.uuidString
	}
	
	// MARK: Helpers
	
	static func pathExists(node: EGPathNode) -> Bool {
		FileManager.default.fileExists(atPath: node.path)
	}
	
	static func isDisabled(node: EGPathNode) -> Bool {
		let defaultVolume = UserDefaults.standard.string(forKey: "epkg.defaultVolume") ?? "/"
		let normalizedDefault = (defaultVolume as NSString).standardizingPath
		
		let disallowedSuffixes = [
			"", // root
			"Applications",
			"Library",
			"Library/Apple",
			"Library/Apple/System",
			"Library/Apple/System/CoreServices",
			"Library/Fonts",
			"Library/Developer",
			"private/var",
			"private/var/db"
		]
		
		let disallowed = disallowedSuffixes.map { suffix in
			((normalizedDefault as NSString).appendingPathComponent(suffix) as NSString).standardizingPath
		}
		
		let nodePath = (node.path as NSString).standardizingPath
		return disallowed.contains(nodePath)
	}
	
	static func revealInFinder(node: EGPathNode) {
		NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: node.path)])
	}
}

// MARK: - PackagePathsDisclosureView
struct EGPackagePathsDisclosureView: View {
	let node: EGPathNode
	@Binding var selectedPaths: Set<String>
	@Binding var expandedNodes: Set<UUID>
	
	// MARK: Body
	
	var body: some View {
		let isExpandedBinding = Binding(
			get: { expandedNodes.contains(node.id) },
			set: { expanded in
				if expanded {
					expandedNodes.insert(node.id)
				} else {
					expandedNodes.remove(node.id)
				}
			}
		)
		
		let isEnabled = EGPathNode.pathExists(node: node) && !EGPathNode.isDisabled(node: node)
		
		if node.children.isEmpty {
			Toggle(isOn: Binding(
				get: { selectedPaths.contains(node.path) },
				set: { isOn in updateSelection(node: node, select: isOn) }
			)) {
				fileRow(for: node)
			}
			.toggleStyle(.checkbox)
			.disabled(!isEnabled)
		} else {
			DisclosureGroup(isExpanded: isExpandedBinding) {
				ForEach(node.children) { child in
					EGPackagePathsDisclosureView(
						node: child,
						selectedPaths: $selectedPaths,
						expandedNodes: $expandedNodes
					)
					.padding(.leading, 1)
				}
			} label: {
				Toggle(isOn: Binding(
					get: { selectedPaths.contains(node.path) },
					set: { isOn in updateSelection(node: node, select: isOn) }
				)) {
					fileRow(for: node)
				}
				.toggleStyle(.checkbox)
				.disabled(!isEnabled)
			}
		}
	}
	
	// MARK: Helpers
	
	private func updateSelection(node: EGPathNode, select: Bool) {
		if select {
			selectedPaths.formUnion(existingPaths(in: node))
		} else {
			selectedPaths.subtract(allPaths(in: node))
		}
	}

	private func allPaths(in node: EGPathNode) -> Set<String> {
		var paths: Set<String> = [node.path]
		for child in node.children {
			paths.formUnion(allPaths(in: child))
		}
		return paths
	}

	private func existingPaths(in node: EGPathNode) -> Set<String> {
		var paths: Set<String> = []
		
		if EGPathNode.pathExists(node: node) {
			paths.insert(node.path)
		}
		
		for child in node.children {
			paths.formUnion(existingPaths(in: child))
		}
		
		return paths
	}
	
	// MARK: Builders
	
	private func fileRow(for node: EGPathNode) -> some View {
		HStack {
			EGFileImage(path: node.path, size: 16)
			Text(node.name)
		}
		.contextMenu {
			Button(.localized("Reveal in Finder")) {
				EGPathNode.revealInFinder(node: node)
			}
			Divider()
			if selectedPaths.contains(node.path) {
				Button(.localized("Deselect Individually")) {
					selectedPaths.remove(node.path)
				}
			} else {
				Button(.localized("Select Individually")) {
					selectedPaths.insert(node.path)
				}
			}
		}
	}
}
