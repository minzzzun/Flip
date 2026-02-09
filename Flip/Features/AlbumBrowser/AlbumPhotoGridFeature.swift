//
//  AlbumPhotoGridFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import UIKit
import ComposableArchitecture

@Reducer
struct AlbumPhotoGridFeature {
    @ObservableState
    struct State: Equatable {
        let albumId: String
        let albumTitle: String
        var photos: [PhotoAssetDTO] = []
        var isLoading = false
        var isLoadingFullImage = false
    }

    enum Action {
        case onAppear
        case photosLoaded(Result<[PhotoAssetDTO], Error>)
        case photoTapped(PhotoAssetDTO)
        case fullImageLoaded(Result<UIImage, Error>)
        case photoSelected(UIImage)
    }

    @Dependency(\.albumClient) var albumClient

    var body: some Reducer<State,Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.photos.isEmpty else { return .none }
                state.isLoading = true
                let albumId = state.albumId
                return .run { send in
                    let result = await Result {
                        try await albumClient.fetchPhotos(albumId)
                    }
                    await send(.photosLoaded(result))
                }

            case let .photosLoaded(.success(photos)):
                state.photos = photos
                state.isLoading = false
                return .none

            case .photosLoaded(.failure):
                state.isLoading = false
                return .none

            case let .photoTapped(photo):
                state.isLoadingFullImage = true
                let assetId = photo.id
                return .run { send in
                    let result = await Result {
                        try await albumClient.loadImage(assetId, CGSize(width: 2000, height: 2000))
                    }
                    await send(.fullImageLoaded(result))
                }

            case let .fullImageLoaded(.success(image)):
                state.isLoadingFullImage = false
                return .send(.photoSelected(image))

            case .fullImageLoaded(.failure):
                state.isLoadingFullImage = false
                return .none

            case .photoSelected:
                // Handled by parent (AlbumListFeature)
                return .none
            }
        }
    }
}
