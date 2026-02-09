//
//  FolderPickerRowView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct FolderPickerRowView: View {
    let name: String
    let systemImage: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.blue)
                    .frame(width: 24)
                Text(name)
                    .font(.body)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .fontWeight(.semibold)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
