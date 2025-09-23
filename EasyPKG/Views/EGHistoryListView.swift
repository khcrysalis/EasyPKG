//
//  HistoryListView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - HistoryListView
struct EGHistoryListView: View {
	@Environment(\.dismiss) private var _dismiss
	@AppStorage("epkg.defaultVolume") private var _defaultVolume: String = "/"
	
	@State private var _historyItems: [EGUtils.HistoryItem] = []
	private var _groupedHistory: [Date: [EGUtils.HistoryItem]] {
		Dictionary(grouping: _historyItems) { item in
			Calendar.current.startOfDay(for: item.date)
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
								LabeledContent(
									item.displayName.isEmpty ? .localized("Unknown") : item.displayName,
									value: "\((item.displayVersion.isEmpty ? "NULL" : item.displayVersion))\n\(item.processName)"
								)
								.labeledContentStyle(.vertical)
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
		self._historyItems = EGUtils.receiptHistoryOnVolume(atPath: _defaultVolume)
	}
}
