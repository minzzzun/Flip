//
//  AlbumPhotoCell.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import Dependencies

struct AlbumPhotoCell: View {
    let assetId: String
    let aspectRatio: CGFloat
    let onTap: () -> Void

    @State private var thumbnail: UIImage?

    var body: some View {
        Button(action: onTap) {
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.15)
                        .overlay { ProgressView() }
                }
            }
            .frame(minHeight: 100, maxHeight: 150)
            .clipped()
        }
        .buttonStyle(.plain)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        @Dependency(\.albumClient) var albumClient
        thumbnail = try? await albumClient.loadImage(assetId, CGSize(width: 300, height: 300))
    }
}
