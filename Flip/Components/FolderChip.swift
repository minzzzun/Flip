//
//  FolderChip.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct FolderChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.12))
                )
        }
        .buttonStyle(.plain)
    }
}
