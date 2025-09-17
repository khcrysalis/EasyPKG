//
//  VerticalLabeledContentStyle.swift
//  easypkg
//
//  Created by samsam on 9/14/25.
//

import SwiftUI

struct VerticalLabeledContentStyle: LabeledContentStyle {
	func makeBody(configuration: Configuration) -> some View {
		VStack(alignment: .leading) {
			configuration.label.font(.headline).fontWeight(.regular)
			configuration.content.font(.subheadline).foregroundStyle(.secondary)
		}
		.padding(.vertical, 4)
	}
}

extension LabeledContentStyle where Self == VerticalLabeledContentStyle {
	static var vertical: VerticalLabeledContentStyle { .init() }
}

