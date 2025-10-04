//
//  HistoryListView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

extension EGHistoryListView {
	struct HistoryItem: Identifiable {
		let id = UUID()
		let date: Date
		let displayName: String
		let displayVersion: String
		let processName: String
	}
}

// MARK: - HistoryListView
struct EGHistoryListView: View {
	@Environment(\.dismiss) private var _dismiss
	@AppStorage("epkg.defaultVolume") private var _defaultVolume: String = "/"
	
	@State private var _historyItems: [HistoryItem] = []
	private var _groupedHistory: [Date: [HistoryItem]] {
		Dictionary(grouping: _historyItems) {
			Calendar.current.startOfDay(for: $0.date)
		}
	}
	
	// MARK: Body
	
	var body: some View {
		NavigationStack {
			List {
				ForEach(_groupedHistory.keys.sorted(by: >), id: \.self) { day in
					Section(header: Text(day, style: .date)) {
						ForEach(_groupedHistory[day] ?? []) { item in
							HStack {
								EGFileImage()
								EGLabeledContent(
									title: item.displayName.isEmpty ? .localized("Unknown") : item.displayName,
									description: "\((item.displayVersion.isEmpty ? .localized("Unknown") : item.displayVersion))\n\(item.processName)"
								)
							}
						}
					}
				}
			}
			.frame(width: 500, height: 600)
			.navigationTitle(.localized("Install History Overall"))
			.navigationSubtitle(.localized("Includes previously installed packages."))
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						_dismiss()
					} label: {
						Text(.localized("Close"))
					}
				}
			}
			.onAppear(perform: _loadHistory)
		}
	}
	
	// MARK: Load
	
	private func _loadHistory() {
		var items: [HistoryItem] = []
		
		for dict in PKInstallHistory.getHistory(onVolume: _defaultVolume).installedItems {
			if let date = dict["date"] as? Date {
				let displayName = dict["displayName"] as? String ?? ""
				let displayVersion = dict["displayVersion"] as? String ?? ""
				let processName = dict["processName"] as? String ?? ""
				
				items.append(HistoryItem(
					date: date,
					displayName: displayName,
					displayVersion: displayVersion,
					processName: processName
				))
			}
		}
		
		self._historyItems = items.sorted { $0.date > $1.date }
	}
}
