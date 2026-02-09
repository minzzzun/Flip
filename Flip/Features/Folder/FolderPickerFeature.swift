//
//  FolderPickerFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct FolderPickerFeature {
    @ObservableState
    struct State: Equatable {
        let entryId: UUID
        let currentFolderId: UUID?
        var folders: [FolderDTO] = []
        var isLoading = false
    }

    enum Action {
        case onAppear
        case foldersLoaded(Result<[FolderDTO], Error>)
        case folderSelected(UUID?)
        case moveCompleted(Result<Void, Error>)
        case moveDone
        case cancelButtonTapped
    }

    @Dependency(\.folderStoreClient) var folderStoreClient
    @Dependency(\.entryStoreClient) var entryStoreClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State,Action> {
        Reduce { state, action in
            switch action {
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

            case let .folderSelected(folderId):
                let entryId = state.entryId
                return .run { send in
                    let result = await Result<Void, Error> {
                        try await entryStoreClient.moveToFolder(entryId, folderId)
                    }
                    await send(.moveCompleted(result))
                }

            case .moveCompleted(.success):
                return .send(.moveDone)

            case .moveCompleted(.failure):
                return .none

            case .moveDone:
                // Handled by parent
                return .run { _ in await dismiss() }

            case .cancelButtonTapped:
                return .run { _ in await dismiss() }
            }
        }
    }
}
