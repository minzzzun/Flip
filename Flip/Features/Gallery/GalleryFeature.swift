//
//  GalleryFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct GalleryFeature {
    @ObservableState
    struct State {
        var entries: [EntryDTO] = []
        var folders: [FolderDTO] = []
        var selectedFolderId: UUID?
        var isLoading = false

        @Presents var addEntry: AddEntryFeature.State?
        @Presents var folderManage: FolderManageFeature.State?
        @Presents var folderPicker: FolderPickerFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var entryToDelete: EntryDTO?
    }

    enum Action {
        case onAppear
        case refreshEntries       // Entry만 재조회 (폴더 선택/이동/추가 후)
        case refreshFolders       // Folder만 재조회 (폴더 관리 후)
        case entriesLoaded(Result<[EntryDTO], Error>)
        case foldersLoaded(Result<[FolderDTO], Error>)

        // Folder filter
        case allFolderSelected
        case folderSelected(UUID)
        case manageFoldersButtonTapped
        case folderManage(PresentationAction<FolderManageFeature.Action>)

        // Folder move
        case entryMoveToFolderRequested(EntryDTO)
        case folderPicker(PresentationAction<FolderPickerFeature.Action>)

        // Navigation
        case addButtonTapped
        case addEntry(PresentationAction<AddEntryFeature.Action>)
        case entryTapped(EntryDTO)

        // Delete
        case entryDeleteRequested(EntryDTO)
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum Alert: Equatable {
            case confirmDelete
        }
    }

    @Dependency(\.entryStoreClient) var entryStoreClient
    @Dependency(\.imageStoreClient) var imageStoreClient
    @Dependency(\.folderStoreClient) var folderStoreClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                // GalleryFeature에서 먼저 체크해 불필요한 actor 진입을 차단
                let needsMigration = !UserDefaults.standard.bool(forKey: "didMigrateImageDimensions_v1")
                let folderId = state.selectedFolderId
                return .merge(
                    .run { send in
                        if needsMigration {
                            try? await entryStoreClient.migrateImageDimensions()
                        }
                        let result = await Result {
                            if let folderId {
                                return try await entryStoreClient.fetchByFolder(folderId)
                            } else {
                                return try await entryStoreClient.fetchAll()
                            }
                        }
                        await send(.entriesLoaded(result))
                    },
                    .run { send in
                        let result = await Result {
                            try await folderStoreClient.fetchAll()
                        }
                        await send(.foldersLoaded(result))
                    }
                )

            case .refreshEntries:
                let folderId = state.selectedFolderId
                return .run { send in
                    let result = await Result {
                        if let folderId {
                            return try await entryStoreClient.fetchByFolder(folderId)
                        } else {
                            return try await entryStoreClient.fetchAll()
                        }
                    }
                    await send(.entriesLoaded(result))
                }

            case .refreshFolders:
                return .run { send in
                    let result = await Result {
                        try await folderStoreClient.fetchAll()
                    }
                    await send(.foldersLoaded(result))
                }

            case let .entriesLoaded(.success(entries)):
                state.entries = entries
                state.isLoading = false
                return .none

            case .entriesLoaded(.failure):
                state.isLoading = false
                return .none

            case let .foldersLoaded(.success(folders)):
                state.folders = folders
                return .none

            case .foldersLoaded(.failure):
                return .none

            // MARK: - Folder filter

            case .allFolderSelected:
                state.selectedFolderId = nil
                return .send(.refreshEntries)

            case let .folderSelected(folderId):
                state.selectedFolderId = folderId
                return .send(.refreshEntries)

            case .manageFoldersButtonTapped:
                state.folderManage = FolderManageFeature.State()
                return .none

            case .folderManage(.presented(.doneButtonTapped)):
                state.folderManage = nil
                // 폴더 관리 후 Entry + Folder 목록 갱신 (migration 제외)
                return .merge(.send(.refreshEntries), .send(.refreshFolders))

            case .folderManage:
                return .none

            // MARK: - Folder move

            case let .entryMoveToFolderRequested(entry):
                state.folderPicker = FolderPickerFeature.State(
                    entryId: entry.id,
                    currentFolderId: entry.folderId
                )
                return .none

            case .folderPicker(.presented(.moveDone)):
                state.folderPicker = nil
                return .send(.refreshEntries)

            case .folderPicker:
                return .none

            // MARK: - Add

            case .addButtonTapped:
                state.addEntry = AddEntryFeature.State(folderId: state.selectedFolderId)
                return .none

            case .addEntry(.presented(.saveDone)):
                state.addEntry = nil
                return .send(.refreshEntries)

            case .addEntry:
                return .none

            case let .entryTapped(entry):
                // Handled by parent (AppFeature) for navigation
                return .none

            // MARK: - Delete

            case let .entryDeleteRequested(entry):
                state.entryToDelete = entry
                state.alert = AlertState {
                    TextState("삭제 확인")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDelete) {
                        TextState("삭제")
                    }
                    ButtonState(role: .cancel) {
                        TextState("취소")
                    }
                } message: {
                    TextState("이 항목을 삭제하시겠습니까?")
                }
                return .none

            case .alert(.presented(.confirmDelete)):
                guard let entry = state.entryToDelete else { return .none }
                let id = entry.id
                let imagePath = entry.imagePath
                let thumbPath = entry.thumbPath
                state.entryToDelete = nil
                return .run { [selectedFolderId = state.selectedFolderId] send in
                    try await entryStoreClient.delete(id)
                    try? await imageStoreClient.delete(imagePath)
                    if let thumbPath {
                        try? await imageStoreClient.delete(thumbPath)
                    }
                    let result = await Result {
                        if let selectedFolderId {
                            return try await entryStoreClient.fetchByFolder(selectedFolderId)
                        } else {
                            return try await entryStoreClient.fetchAll()
                        }
                    }
                    await send(.entriesLoaded(result))
                }

            case .alert:
                state.entryToDelete = nil
                return .none
            }
        }
        .ifLet(\.$addEntry, action: \.addEntry) {
            AddEntryFeature()
        }
        .ifLet(\.$folderManage, action: \.folderManage) {
            FolderManageFeature()
        }
        .ifLet(\.$folderPicker, action: \.folderPicker) {
            FolderPickerFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
