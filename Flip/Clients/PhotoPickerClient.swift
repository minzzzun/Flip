//
//  PhotoPickerClient.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import UIKit
import PhotosUI
import Dependencies
import SwiftUI

struct PhotoPickerClient {
    var loadImage: @Sendable (_ item: PhotosPickerItem) async throws -> UIImage
}

// MARK: - DependencyKey

extension PhotoPickerClient: DependencyKey {
    static let liveValue = Self(
        loadImage: { item in
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw PhotoPickerError.loadFailed
            }
            guard let image = UIImage(data: data) else {
                throw PhotoPickerError.invalidImageData
            }
            return image
        }
    )

    static let testValue = Self(
        loadImage: { _ in UIImage(systemName: "photo")! }
    )
}

// MARK: - Error

enum PhotoPickerError: LocalizedError {
    case loadFailed
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .loadFailed:
            return "사진을 불러올 수 없습니다."
        case .invalidImageData:
            return "유효하지 않은 이미지 데이터입니다."
        }
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var photoPickerClient: PhotoPickerClient {
        get { self[PhotoPickerClient.self] }
        set { self[PhotoPickerClient.self] = newValue }
    }
}
