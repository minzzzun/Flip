//
//  EntryCardView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct EntryCardView: View {
    let memo: String
    let onTap: () -> Void
    let onDelete: () -> Void
    let onMoveToFolder: () -> Void
    let loadThumbnail: @Sendable () async -> UIImage?

    @State private var thumbnailImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail
            Group {
                if let thumbnailImage {
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                }
            }
            .frame(minHeight: 120, maxHeight: 300)
            .clipped()

            // Memo preview
//            if !memo.isEmpty {
//                Text(memo)
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//                    .lineLimit(3)
//                    .padding(.horizontal, 8)
//                    .padding(.vertical, 6)
//            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            Button {
                onMoveToFolder()
            } label: {
                Label("폴더 이동", systemImage: "folder")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("삭제", systemImage: "trash")
            }
        }
        .task {
            if thumbnailImage == nil {
                thumbnailImage = await loadThumbnail()
            }
        }
    }
}
