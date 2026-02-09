//
//  AddEntryView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import PhotosUI
import ComposableArchitecture

struct AddEntryView: View {
    @Bindable var store: StoreOf<AddEntryFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                PhotoPickerSection(
                    selectedImage: store.selectedImage,
                    isLoading: store.isLoadingPhoto,
                    photosPickerItem: $store.photosPickerItem.sending(\.photoPickerItemChanged),
                    onAlbumBrowse: { store.send(.albumBrowseButtonTapped) }
                )

                MemoInputSection(
                    memo: $store.memo
                )
            }
            .padding()
        }
        .navigationTitle("새 기록")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    store.send(.cancelButtonTapped)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if store.isSaving {
                    ProgressView()
                } else {
                    Button("저장") {
                        store.send(.saveButtonTapped)
                    }
                    .disabled(store.selectedImage == nil)
                }
            }
        }
        .interactiveDismissDisabled(store.isSaving)
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.albumBrowser, action: \.albumBrowser)) { albumStore in
            AlbumListView(store: albumStore)
        }
    }
}
