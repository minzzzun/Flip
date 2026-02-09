//
//  FolderManageView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct FolderManageView: View {
    @Bindable var store: StoreOf<FolderManageFeature>

    var body: some View {
        List {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if store.folders.isEmpty {
                Text("폴더가 없습니다")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(store.folders) { folder in
                    FolderManageRowView(
                        name: folder.name,
                        onRename: { store.send(.folderRenameTapped(folder)) },
                        onDelete: { store.send(.folderDeleteRequested(folder)) }
                    )
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("폴더 관리")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("완료") {
                    store.send(.doneButtonTapped)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.addFolderButtonTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .alert("새 폴더", isPresented: $store.isAddingFolder) {
            TextField("폴더 이름", text: $store.newFolderName)
            Button("추가") { store.send(.addFolderConfirmed) }
            Button("취소", role: .cancel) { store.send(.addFolderCancelled) }
        }
        .alert("이름 변경", isPresented: Binding(
            get: { store.renamingFolder != nil },
            set: { if !$0 { store.send(.renameCancelled) } }
        )) {
            TextField("폴더 이름", text: $store.renameText)
            Button("변경") { store.send(.renameConfirmed) }
            Button("취소", role: .cancel) { store.send(.renameCancelled) }
        }
    }
}
