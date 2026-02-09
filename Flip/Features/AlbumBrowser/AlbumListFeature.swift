//
//  AlbumListFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import UIKit
import Photos
import ComposableArchitecture

@Reducer
struct AlbumListFeature {
    @ObservableState
    struct State: Equatable {
        var albums: [AlbumDTO] = []
        var isLoading = false
        var authorizationStatus: PHAuthorizationStatus?
        var path = StackState<AlbumPhotoGridFeature.State>()
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case onAppear
        case authorizationResponse(PHAuthorizationStatus)
        case albumsLoaded(Result<[AlbumDTO], Error>)
        case albumTapped(AlbumDTO)
        case path(StackActionOf<AlbumPhotoGridFeature>)
        case photoSelected(UIImage)
        case cancelButtonTapped
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum Alert: Equatable {}
    }

    @Dependency(\.albumClient) var albumClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.albums.isEmpty else { return .none }
                state.isLoading = true
                return .run { send in
                    let status = await albumClient.requestAuthorization()
                    await send(.authorizationResponse(status))
                }

            case let .authorizationResponse(status):
                state.authorizationStatus = status
                switch status {
                case .authorized, .limited:
                    return .run { send in
                        let result = await Result {
                            try await albumClient.fetchAlbums()
                        }
                        await send(.albumsLoaded(result))
                    }
                default:
                    state.isLoading = false
                    state.alert = AlertState {
                        TextState("접근 권한 필요")
                    } actions: {
                        ButtonState(role: .cancel) {
                            TextState("확인")
                        }
                    } message: {
                        TextState("설정에서 사진 라이브러리 접근 권한을 허용해주세요.")
                    }
                    return .none
                }

            case let .albumsLoaded(.success(albums)):
                state.albums = albums
                state.isLoading = false
                return .none

            case .albumsLoaded(.failure):
                state.isLoading = false
                return .none

            case let .albumTapped(album):
                state.path.append(
                    AlbumPhotoGridFeature.State(albumId: album.id, albumTitle: album.title)
                )
                return .none

            case let .path(.element(_, action: .photoSelected(image))):
                return .send(.photoSelected(image))

            case .path:
                return .none

            case .photoSelected:
                // Handled by parent (AddEntryFeature)
                return .none

            case .cancelButtonTapped:
                return .run { _ in await dismiss() }

            case .alert:
                return .none
            }
        }
        .forEach(\.path, action: \.path) {
            AlbumPhotoGridFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
