//
//  AlbumListView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct AlbumListView: View {
    @Bindable var store: StoreOf<AlbumListFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            Group {
                if store.isLoading {
                    ProgressView("앨범 불러오는 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.albums.isEmpty {
                    Text("앨범이 없습니다")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(store.albums) { album in
                        AlbumRowView(
                            title: album.title,
                            count: album.count,
                            thumbnailAssetId: album.thumbnailAssetId,
                            onTap: { store.send(.albumTapped(album)) }
                        )
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("앨범 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        store.send(.cancelButtonTapped)
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
            .alert($store.scope(state: \.alert, action: \.alert))
        } destination: { store in
            AlbumPhotoGridView(store: store)
        }
    }
}
