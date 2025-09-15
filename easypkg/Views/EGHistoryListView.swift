//
//  HistoryListView.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

// MARK: - HistoryListView
struct EGHistoryListView: View {
	@Environment(\.dismiss) private var dismiss
	
	@AppStorage("epkg.defaultVolume") var defaultVolume: String = "/"
	
	@State private var historyItems: [EGUtils.HistoryItem] = []
	
	private var groupedHistory: [Date: [EGUtils.HistoryItem]] {
		Dictionary(grouping: historyItems) { item in
			Calendar.current.startOfDay(for: item.date)
		}
	}
	
	// MARK: Body
	
	var body: some View {
		NavigationStack {
			List {
				ForEach(groupedHistory.keys.sorted(by: >), id: \.self) { day in
					Section(header: Text(day, style: .date)) {
						ForEach(groupedHistory[day] ?? []) { item in
							HStack {
								EGFileImage()
								LabeledContent(
									item.displayName.isEmpty ? "Unknown" : item.displayName,
									value: "\((item.displayVersion.isEmpty ? "NULL" : item.displayVersion))\n\(item.processName)"
								)
								.labeledContentStyle(.vertical)
							}
						}
					}
				}
			}
			.frame(width: 500, height: 600)
			.navigationTitle("Install History")
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button {
						dismiss()
					} label: {
						Text("Close")
					}
				}
			}
			.onAppear(perform: loadHistory)
		}
	}
	
	// MARK: Load
	
	private func loadHistory() {
		self.historyItems = EGUtils.receiptHistoryOnVolume(atPath: defaultVolume)
	}
}
