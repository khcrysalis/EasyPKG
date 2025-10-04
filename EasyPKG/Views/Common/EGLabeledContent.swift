//
//  VerticalLabeledContentStyle.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

struct EGLabeledContent: View {
	var title: String
	var description: String
	
	var body: some View {
		VStack(alignment: .leading) {
			Text(title)
				.font(.headline)
				.fontWeight(.regular)
			Text(description)
				.font(.subheadline)
				.foregroundStyle(.secondary)
		}
		.padding(.vertical, 4)
	}
}
