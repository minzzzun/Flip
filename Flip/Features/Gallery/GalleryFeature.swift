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
        var isLoading = false

        @Presents var addEntry: AddEntryFeature.State?
        @Presents var alert: AlertState<Action.Alert>?

        var entryToDelete: EntryDTO?
    }

    enum Action {
        case onAppear
        case entriesLoaded(Result<[EntryDTO], Error>)

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

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let result = await Result {
                        try await entryStoreClient.fetchAll()
                    }
                    await send(.entriesLoaded(result))
                }

            case let .entriesLoaded(.success(entries)):
                state.entries = entries
                state.isLoading = false
                return .none

            case .entriesLoaded(.failure):
                state.isLoading = false
                return .none

            case .addButtonTapped:
                state.addEntry = AddEntryFeature.State()
                return .none

            case .addEntry(.presented(.saveDone)):
                state.addEntry = nil
                return .run { send in
                    let result = await Result {
                        try await entryStoreClient.fetchAll()
                    }
                    await send(.entriesLoaded(result))
                }

            case .addEntry:
                return .none

            case let .entryTapped(entry):
                // Handled by parent (AppFeature) for navigation
                return .none

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
                return .run { send in
                    try await entryStoreClient.delete(id)
                    try? await imageStoreClient.delete(imagePath)
                    if let thumbPath {
                        try? await imageStoreClient.delete(thumbPath)
                    }
                    let result = await Result {
                        try await entryStoreClient.fetchAll()
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
        .ifLet(\.$alert, action: \.alert)
    }
}
