//
//  EntryDetailFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import UIKit
import ComposableArchitecture

@Reducer
struct EntryDetailFeature {
    @ObservableState
    struct State: Equatable {
        var entry: EntryDTO
        var image: UIImage?
        var isFlipped = false
        var isLoadingImage = false
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var editMemo: EditMemoFeature.State?
        @Presents var folderPicker: FolderPickerFeature.State?
    }

    enum Action {
        case onAppear
        case imageLoaded(Result<UIImage, Error>)

        case cardTapped
        case editButtonTapped
        case editMemo(PresentationAction<EditMemoFeature.Action>)
        case moveToFolderButtonTapped
        case folderPicker(PresentationAction<FolderPickerFeature.Action>)
        case deleteButtonTapped
        case alert(PresentationAction<Alert>)
        case deleteCompleted(Result<Void, Error>)
        case popDetail

        @CasePathable
        enum Alert: Equatable {
            case confirmDelete
        }
    }

    @Dependency(\.imageStoreClient) var imageStoreClient
    @Dependency(\.entryStoreClient) var entryStoreClient
    @Dependency(\.hapticClient) var hapticClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action>  {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoadingImage = true
                let imagePath = state.entry.imagePath
                return .run { send in
                    let result = await Result {
                        try await imageStoreClient.loadImage(imagePath)
                    }
                    await send(.imageLoaded(result))
                }

            case let .imageLoaded(.success(image)):
                state.image = image
                state.isLoadingImage = false
                return .none

            case .imageLoaded(.failure):
                state.isLoadingImage = false
                return .none

            case .cardTapped:
                state.isFlipped.toggle()
                return .run { _ in
                    hapticClient.impact(.light)
                }

            case .editButtonTapped:
                state.editMemo = EditMemoFeature.State(
                    entryId: state.entry.id,
                    memo: state.entry.memo
                )
                return .none

            case let .editMemo(.presented(.saveDone(updatedEntry))):
                state.entry = updatedEntry
                state.editMemo = nil
                return .none

            case .editMemo:
                return .none

            case .moveToFolderButtonTapped:
                state.folderPicker = FolderPickerFeature.State(
                    entryId: state.entry.id,
                    currentFolderId: state.entry.folderId
                )
                return .none

            case .folderPicker(.presented(.moveDone)):
                state.folderPicker = nil
                return .none

            case .folderPicker:
                return .none

            case .deleteButtonTapped:
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
                let entry = state.entry
                return .run { send in
                    let result = await Result<Void, Error> {
                        try await entryStoreClient.delete(entry.id)
                        try? await imageStoreClient.delete(entry.imagePath)
                        if let thumbPath = entry.thumbPath {
                            try? await imageStoreClient.delete(thumbPath)
                        }
                    }
                    await send(.deleteCompleted(result))
                }

            case .deleteCompleted(.success):
                return .send(.popDetail)

            case let .deleteCompleted(.failure(error)):
                state.alert = AlertState {
                    TextState("삭제 실패")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .popDetail:
                // Handled by parent (AppFeature)
                return .run { _ in await dismiss() }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$editMemo, action: \.editMemo) {
            EditMemoFeature()
        }
        .ifLet(\.$folderPicker, action: \.folderPicker) {
            FolderPickerFeature()
        }
    }
}
