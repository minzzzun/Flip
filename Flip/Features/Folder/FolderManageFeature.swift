//
//  FolderManageFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct FolderManageFeature {
    @ObservableState
    struct State: Equatable {
        var folders: [FolderDTO] = []
        var isLoading = false
        var newFolderName: String = ""
        var isAddingFolder = false
        var renamingFolder: FolderDTO?
        var renameText: String = ""
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case foldersLoaded(Result<[FolderDTO], Error>)

        // Add
        case addFolderButtonTapped
        case addFolderConfirmed
        case addFolderCancelled
        case folderAdded(Result<FolderDTO, Error>)

        // Rename
        case folderRenameTapped(FolderDTO)
        case renameConfirmed
        case renameCancelled
        case folderRenamed(Result<FolderDTO, Error>)

        // Delete
        case folderDeleteRequested(FolderDTO)
        case alert(PresentationAction<Alert>)
        case folderDeleted(Result<Void, Error>)

        case doneButtonTapped

        @CasePathable
        enum Alert: Equatable {
            case confirmDelete(UUID)
        }
    }

    @Dependency(\.folderStoreClient) var folderStoreClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let result = await Result {
                        try await folderStoreClient.fetchAll()
                    }
                    await send(.foldersLoaded(result))
                }

            case let .foldersLoaded(.success(folders)):
                state.folders = folders
                state.isLoading = false
                return .none

            case .foldersLoaded(.failure):
                state.isLoading = false
                return .none

            // MARK: - Add

            case .addFolderButtonTapped:
                state.isAddingFolder = true
                state.newFolderName = ""
                return .none

            case .addFolderConfirmed:
                let name = state.newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else {
                    state.isAddingFolder = false
                    return .none
                }
                state.isAddingFolder = false
                return .run { send in
                    let result = await Result {
                        try await folderStoreClient.add(name)
                    }
                    await send(.folderAdded(result))
                }

            case .addFolderCancelled:
                state.isAddingFolder = false
                state.newFolderName = ""
                return .none

            case let .folderAdded(.success(folder)):
                state.folders.append(folder)
                return .none

            case .folderAdded(.failure):
                return .none

            // MARK: - Rename

            case let .folderRenameTapped(folder):
                state.renamingFolder = folder
                state.renameText = folder.name
                return .none

            case .renameConfirmed:
                guard let folder = state.renamingFolder else { return .none }
                let newName = state.renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !newName.isEmpty else {
                    state.renamingFolder = nil
                    return .none
                }
                state.renamingFolder = nil
                let folderId = folder.id
                return .run { send in
                    let result = await Result {
                        try await folderStoreClient.rename(folderId, newName)
                    }
                    await send(.folderRenamed(result))
                }

            case .renameCancelled:
                state.renamingFolder = nil
                state.renameText = ""
                return .none

            case let .folderRenamed(.success(updatedFolder)):
                if let index = state.folders.firstIndex(where: { $0.id == updatedFolder.id }) {
                    state.folders[index] = updatedFolder
                }
                return .none

            case .folderRenamed(.failure):
                return .none

            // MARK: - Delete

            case let .folderDeleteRequested(folder):
                state.alert = AlertState {
                    TextState("폴더 삭제")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete(folder.id)) {
                        TextState("삭제")
                    }
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                } message: {
                    TextState("'\(folder.name)' 폴더를 삭제하시겠습니까?\n폴더 내 항목은 '전체'로 이동됩니다.")
                }
                return .none

            case let .alert(.presented(.confirmDelete(folderId))):
                return .run { send in
                    let result = await Result<Void, Error> {
                        try await folderStoreClient.delete(folderId)
                    }
                    await send(.folderDeleted(result))
                }

            case .folderDeleted(.success):
                return .run { send in
                    let result = await Result {
                        try await folderStoreClient.fetchAll()
                    }
                    await send(.foldersLoaded(result))
                }

            case .folderDeleted(.failure):
                return .none

            case .alert:
                return .none

            case .doneButtonTapped:
                return .run { _ in await dismiss() }
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
