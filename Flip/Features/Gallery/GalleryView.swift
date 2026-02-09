//
//  GalleryView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct GalleryView: View {
    @Bindable var store: StoreOf<GalleryFeature>

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                if store.isLoading && store.entries.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if store.entries.isEmpty {
                    GalleryEmptyStateView()
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(store.entries) { entry in
                            EntryCardView(
                                memo: entry.memo,
                                onTap: {
                                    store.send(.entryTapped(entry))
                                },
                                onDelete: {
                                    store.send(.entryDeleteRequested(entry))
                                },
                                loadThumbnail: { [thumbPath = entry.thumbPath, imagePath = entry.imagePath] in
                                    @Dependency(\.imageStoreClient) var imageStoreClient
                                    let path = thumbPath ?? imagePath
                                    return try? await imageStoreClient.loadImage(path)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
            }

            FABButton {
                store.send(.addButtonTapped)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Flip")
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.addEntry, action: \.addEntry)) { addStore in
            NavigationStack {
                AddEntryView(store: addStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
