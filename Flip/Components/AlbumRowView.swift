//
//  AlbumRowView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import Photos
import Dependencies

struct AlbumRowView: View {
    let title: String
    let count: Int
    let thumbnailAssetId: String?
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Group {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.2)
                            .overlay {
                                Image(systemName: "photo")
                                    .foregroundStyle(.tertiary)
                            }
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    Text("\(count)장")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let assetId = thumbnailAssetId else { return }
        @Dependency(\.albumClient) var albumClient
        thumbnail = try? await albumClient.loadImage(assetId, CGSize(width: 128, height: 128))
    }
}
