//
//  FolderPickerView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct FolderPickerView: View {
    let store: StoreOf<FolderPickerFeature>

    var body: some View {
        List {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                // "없음" (폴더 해제)
                FolderPickerRowView(
                    name: "폴더 없음",
                    systemImage: "tray",
                    isSelected: store.currentFolderId == nil,
                    onTap: { store.send(.folderSelected(nil)) }
                )

                ForEach(store.folders) { folder in
                    FolderPickerRowView(
                        name: folder.name,
                        systemImage: "folder.fill",
                        isSelected: store.currentFolderId == folder.id,
                        onTap: { store.send(.folderSelected(folder.id)) }
                    )
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("폴더로 이동")
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
    }
}
