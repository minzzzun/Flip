//
//  AlbumClient.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import UIKit
import Photos
import Dependencies

// MARK: - DTOs

struct AlbumDTO: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let count: Int
    let thumbnailAssetId: String?
}

struct PhotoAssetDTO: Equatable, Identifiable, Sendable {
    let id: String
    let creationDate: Date?
    let pixelWidth: Int
    let pixelHeight: Int
}

// MARK: - Interface

struct AlbumClient {
    var requestAuthorization: @Sendable () async -> PHAuthorizationStatus
    var fetchAlbums: @Sendable () async throws -> [AlbumDTO]
    var fetchPhotos: @Sendable (_ albumId: String) async throws -> [PhotoAssetDTO]
    var loadImage: @Sendable (_ assetId: String, _ targetSize: CGSize) async throws -> UIImage
}

// MARK: - DependencyKey

extension AlbumClient: DependencyKey {
    static let liveValue = Self(
        requestAuthorization: {
            await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        },

        fetchAlbums: {
            var albums: [AlbumDTO] = []

            // Smart albums (Recents, Favorites, Screenshots, etc.)
            let smartAlbumTypes: [PHAssetCollectionSubtype] = [
                .smartAlbumUserLibrary,
                .smartAlbumFavorites,
                .smartAlbumScreenshots,
                .smartAlbumSelfPortraits,
                .smartAlbumPanoramas,
                .smartAlbumLivePhotos,
            ]

            for subtype in smartAlbumTypes {
                let result = PHAssetCollection.fetchAssetCollections(
                    with: .smartAlbum,
                    subtype: subtype,
                    options: nil
                )
                result.enumerateObjects { collection, _, _ in
                    let fetchOptions = PHFetchOptions()
                    fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                    let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                    guard assets.count > 0 else { return }

                    let thumbnailAssetId = assets.lastObject?.localIdentifier
                    albums.append(AlbumDTO(
                        id: collection.localIdentifier,
                        title: collection.localizedTitle ?? "알 수 없는 앨범",
                        count: assets.count,
                        thumbnailAssetId: thumbnailAssetId
                    ))
                }
            }

            // User-created albums
            let userAlbums = PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .albumRegular,
                options: nil
            )
            userAlbums.enumerateObjects { collection, _, _ in
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
                let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                guard assets.count > 0 else { return }

                let thumbnailAssetId = assets.lastObject?.localIdentifier
                albums.append(AlbumDTO(
                    id: collection.localIdentifier,
                    title: collection.localizedTitle ?? "알 수 없는 앨범",
                    count: assets.count,
                    thumbnailAssetId: thumbnailAssetId
                ))
            }

            return albums
        },

        fetchPhotos: { albumId in
            let collections = PHAssetCollection.fetchAssetCollections(
                withLocalIdentifiers: [albumId],
                options: nil
            )
            guard let collection = collections.firstObject else {
                throw AlbumClientError.albumNotFound
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

            let assets = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            var photos: [PhotoAssetDTO] = []
            assets.enumerateObjects { asset, _, _ in
                photos.append(PhotoAssetDTO(
                    id: asset.localIdentifier,
                    creationDate: asset.creationDate,
                    pixelWidth: asset.pixelWidth,
                    pixelHeight: asset.pixelHeight
                ))
            }
            return photos
        },

        loadImage: { assetId, targetSize in
            let assets = PHAsset.fetchAssets(
                withLocalIdentifiers: [assetId],
                options: nil
            )
            guard let asset = assets.firstObject else {
                throw AlbumClientError.assetNotFound
            }

            return try await withCheckedThrowingContinuation { continuation in
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.resizeMode = .exact

                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: options
                ) { image, info in
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                    guard !isDegraded else { return }

                    if let image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: AlbumClientError.imageLoadFailed)
                    }
                }
            }
        }
    )

    static let testValue = Self(
        requestAuthorization: { .authorized },
        fetchAlbums: { [] },
        fetchPhotos: { _ in [] },
        loadImage: { _, _ in UIImage(systemName: "photo")! }
    )
}

// MARK: - Error

enum AlbumClientError: LocalizedError {
    case albumNotFound
    case assetNotFound
    case imageLoadFailed
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .albumNotFound:
            return "앨범을 찾을 수 없습니다."
        case .assetNotFound:
            return "사진을 찾을 수 없습니다."
        case .imageLoadFailed:
            return "이미지를 불러올 수 없습니다."
        case .accessDenied:
            return "사진 라이브러리 접근 권한이 필요합니다."
        }
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var albumClient: AlbumClient {
        get { self[AlbumClient.self] }
        set { self[AlbumClient.self] = newValue }
    }
}
