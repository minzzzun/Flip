//
//  ImageStoreClient.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import UIKit
import Dependencies

struct ImageStoreClient {
    var saveOriginal: @Sendable (_ image: UIImage) async throws -> ImageSaveResult
    var saveThumbnail: @Sendable (_ image: UIImage) async throws -> ImageSaveResult
    var loadImage: @Sendable (_ path: String) async throws -> UIImage
    var delete: @Sendable (_ path: String) async throws -> Void
}

// MARK: - ImageSaveResult

struct ImageSaveResult: Sendable {
    let filename: String
    let width: Double
    let height: Double
}

// MARK: - DependencyKey

extension ImageStoreClient: DependencyKey {
    static let liveValue = Self(
        saveOriginal: { image in
            let directory = try Self.imagesDirectory()
            let filename = UUID().uuidString + ".jpg"
            let fileURL = directory.appendingPathComponent(filename)

            guard let data = image.jpegData(compressionQuality: 0.8) else {
                throw ImageStoreError.compressionFailed
            }
            try data.write(to: fileURL, options: .atomic)

            return ImageSaveResult(
                filename: filename,
                width: Double(image.size.width),
                height: Double(image.size.height)
            )
        },
        saveThumbnail: { image in
            let directory = try Self.thumbnailsDirectory()
            let filename = "thumb_" + UUID().uuidString + ".jpg"
            let fileURL = directory.appendingPathComponent(filename)

            let resized = Self.resizeImage(image, maxShortSide: 500)
            guard let data = resized.jpegData(compressionQuality: 0.7) else {
                throw ImageStoreError.compressionFailed
            }
            try data.write(to: fileURL, options: .atomic)

            return ImageSaveResult(
                filename: filename,
                width: Double(resized.size.width),
                height: Double(resized.size.height)
            )
        },
        loadImage: { path in
            let fileURL = try Self.resolveURL(for: path)
            guard let data = try? Data(contentsOf: fileURL),
                  let image = UIImage(data: data) else {
                throw ImageStoreError.loadFailed
            }
            return image
        },
        delete: { path in
            let fileURL = try Self.resolveURL(for: path)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
    )

    static let testValue = Self(
        saveOriginal: { _ in ImageSaveResult(filename: "test_original.jpg", width: 100, height: 100) },
        saveThumbnail: { _ in ImageSaveResult(filename: "test_thumb.jpg", width: 100, height: 100) },
        loadImage: { _ in UIImage(systemName: "photo")! },
        delete: { _ in }
    )
}

// MARK: - Helpers

private extension ImageStoreClient {
    static func imagesDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("images", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func thumbnailsDirectory() throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let dir = base.appendingPathComponent("thumbnails", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func resolveURL(for path: String) throws -> URL {
        if path.hasPrefix("thumb_") {
            return try thumbnailsDirectory().appendingPathComponent(path)
        } else {
            return try imagesDirectory().appendingPathComponent(path)
        }
    }

    static func resizeImage(_ image: UIImage, maxShortSide: CGFloat) -> UIImage {
        let size = image.size
        let shortSide = min(size.width, size.height)

        guard shortSide > maxShortSide else { return image }

        let scale = maxShortSide / shortSide
        let newSize = CGSize(
            width: size.width * scale,
            height: size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - Error

enum ImageStoreError: LocalizedError {
    case compressionFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "이미지 압축에 실패했습니다."
        case .loadFailed:
            return "이미지를 불러올 수 없습니다."
        }
    }
}

// MARK: - DependencyValues

extension DependencyValues {
    var imageStoreClient: ImageStoreClient {
        get { self[ImageStoreClient.self] }
        set { self[ImageStoreClient.self] = newValue }
    }
}
