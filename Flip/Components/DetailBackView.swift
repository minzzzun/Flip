//
//  DetailBackView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct DetailBackView: View {
    let memo: String
    let createdAt: Date
    let maxWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(memo.isEmpty ? "메모 없음" : memo)
                .font(.body)
                .foregroundStyle(memo.isEmpty ? .tertiary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Text(createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: maxWidth)
        .frame(minHeight: 300)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
