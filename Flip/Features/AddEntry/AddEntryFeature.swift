//
//  AddEntryFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import UIKit
import PhotosUI
import ComposableArchitecture
import SwiftUI


@Reducer
struct AddEntryFeature {
    @ObservableState
    struct State {
        var selectedImage: UIImage?
        var photosPickerItem: PhotosPickerItem?
        var memo: String = ""
        var isSaving = false
        var isLoadingPhoto = false
        @Presents var alert: AlertState<Action.Alert>?
        @Presents var albumBrowser: AlbumListFeature.State?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)

        // Photo
        case photoPickerItemChanged(PhotosPickerItem?)
        case photoLoaded(Result<UIImage, Error>)

        // Album Browser
        case albumBrowseButtonTapped
        case albumBrowser(PresentationAction<AlbumListFeature.Action>)

        // Save
        case saveButtonTapped
        case saveResponse(Result<Void, Error>)
        case saveDone

        // Alert
        case alert(PresentationAction<Alert>)
        case cancelButtonTapped

        @CasePathable
        enum Alert: Equatable {}
    }

    @Dependency(\.photoPickerClient) var photoPickerClient
    @Dependency(\.imageStoreClient) var imageStoreClient
    @Dependency(\.entryStoreClient) var entryStoreClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case let .photoPickerItemChanged(item):
                state.photosPickerItem = item
                guard let item else {
                    state.selectedImage = nil
                    return .none
                }
                state.isLoadingPhoto = true
                return .run { send in
                    let result = await Result {
                        try await photoPickerClient.loadImage(item)
                    }
                    await send(.photoLoaded(result))
                }

            case let .photoLoaded(.success(image)):
                state.selectedImage = image
                state.isLoadingPhoto = false
                return .none

            case let .photoLoaded(.failure(error)):
                state.isLoadingPhoto = false
                state.selectedImage = nil
                state.alert = AlertState {
                    TextState("사진 로드 실패")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .albumBrowseButtonTapped:
                state.albumBrowser = AlbumListFeature.State()
                return .none

            case let .albumBrowser(.presented(.photoSelected(image))):
                state.selectedImage = image
                state.photosPickerItem = nil
                state.albumBrowser = nil
                return .none

            case .albumBrowser:
                return .none

            case .saveButtonTapped:
                guard let image = state.selectedImage else { return .none }
                state.isSaving = true

                let memo = state.memo
                return .run { send in
                    let result = await Result<Void, Error> {
                        let originalResult = try await imageStoreClient.saveOriginal(image)
                        let thumbResult = try await imageStoreClient.saveThumbnail(image)

                        let dto = EntryDTO(
                            id: UUID(),
                            createdAt: .now,
                            updatedAt: .now,
                            memo: memo,
                            imagePath: originalResult.filename,
                            thumbPath: thumbResult.filename,
                            title: nil,
                            folderId: nil,
                            imageWidth: originalResult.width,
                            imageHeight: originalResult.height
                        )
                        try await entryStoreClient.add(dto)
                    }
                    await send(.saveResponse(result))
                }

            case .saveResponse(.success):
                state.isSaving = false
                return .send(.saveDone)

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.alert = AlertState {
                    TextState("저장 실패")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .saveDone:
                // Handled by parent (GalleryFeature)
                return .none

            case .cancelButtonTapped:
                return .run { _ in await dismiss() }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$albumBrowser, action: \.albumBrowser) {
            AlbumListFeature()
        }
    }
}
