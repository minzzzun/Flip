//
//  AlbumPhotoGridView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct AlbumPhotoGridView: View {
    let store: StoreOf<AlbumPhotoGridFeature>

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
    ]

    var body: some View {
        ZStack {
            ScrollView {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(store.photos) { photo in
                            AlbumPhotoCell(
                                assetId: photo.id,
                                aspectRatio: CGFloat(photo.pixelWidth) / max(CGFloat(photo.pixelHeight), 1),
                                onTap: { store.send(.photoTapped(photo)) }
                            )
                        }
                    }
                }
            }

            if store.isLoadingFullImage {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView("이미지 로드 중...")
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle(store.albumTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            store.send(.onAppear)
        }
    }
}
