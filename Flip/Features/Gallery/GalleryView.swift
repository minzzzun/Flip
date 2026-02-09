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

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                if !store.folders.isEmpty {
                    FolderChipBar(
                        folders: store.folders,
                        selectedFolderId: store.selectedFolderId,
                        onSelectAll: { store.send(.allFolderSelected) },
                        onSelectFolder: { id in store.send(.folderSelected(id)) },
                        onManageFolders: { store.send(.manageFoldersButtonTapped) }
                    )
                    .padding(.bottom, 10)
                }

                if store.isLoading && store.entries.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 300)
                } else if store.entries.isEmpty {
                    GalleryEmptyStateView()
                } else {
                    GeometryReader { geometry in
                        WaterfallCollectionView(
                            entries: store.entries,
                            numberOfColumns: WaterfallLayoutHelper.calculateNumberOfColumns(for: geometry.size.width),
                            onTap: { entry in
                                store.send(.entryTapped(entry))
                            },
                            onDelete: { entry in
                                store.send(.entryDeleteRequested(entry))
                            },
                            onMoveToFolder: { entry in
                                store.send(.entryMoveToFolderRequested(entry))
                            }
                        )
                        .padding(.horizontal, 12)
                        .padding(.bottom, 80)
                    }
                }
            }

            FABButton {
                store.send(.addButtonTapped)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 24)
        }
        .navigationTitle("Flip")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.manageFoldersButtonTapped)
                } label: {
                    Image(systemName: "folder.badge.gearshape")
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .sheet(item: $store.scope(state: \.addEntry, action: \.addEntry)) { addStore in
            NavigationStack {
                AddEntryView(store: addStore)
            }
        }
        .sheet(item: $store.scope(state: \.folderManage, action: \.folderManage)) { folderStore in
            NavigationStack {
                FolderManageView(store: folderStore)
            }
        }
        .sheet(item: $store.scope(state: \.folderPicker, action: \.folderPicker)) { pickerStore in
            NavigationStack {
                FolderPickerView(store: pickerStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
