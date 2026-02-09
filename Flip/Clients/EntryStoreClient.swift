//
//  EntryStoreClient.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import SwiftData
import Dependencies
import UIKit
import ImageIO

struct EntryStoreClient {
    var fetchAll: @Sendable () async throws -> [EntryDTO]
    var fetchByFolder: @Sendable (_ folderId: UUID) async throws -> [EntryDTO]
    var add: @Sendable (_ dto: EntryDTO) async throws -> Void
    var delete: @Sendable (_ id: UUID) async throws -> Void
    var updateMemo: @Sendable (_ id: UUID, _ memo: String) async throws -> EntryDTO
    var moveToFolder: @Sendable (_ entryId: UUID, _ folderId: UUID?) async throws -> Void
    var migrateImageDimensions: @Sendable () async throws -> Void
}

// MARK: - EntryDTO (Sendable transfer object)

struct EntryDTO: Equatable, Identifiable, Sendable {
    let id: UUID
    let createdAt: Date
    let updatedAt: Date
    let memo: String
    let imagePath: String
    let thumbPath: String?
    let title: String?
    let folderId: UUID?
    let imageWidth: Double?
    let imageHeight: Double?
}

extension EntryDTO {
    init(from entry: Entry) {
        self.id = entry.id
        self.createdAt = entry.createdAt
        self.updatedAt = entry.updatedAt
        self.memo = entry.memo
        self.imagePath = entry.imagePath
        self.thumbPath = entry.thumbPath
        self.title = entry.title
        self.folderId = entry.folderId
        self.imageWidth = entry.imageWidth
        self.imageHeight = entry.imageHeight
    }
}

// MARK: - ModelActor for background SwiftData access

@ModelActor
actor EntryModelActor {
    func fetchAll() throws -> [EntryDTO] {
        let descriptor = FetchDescriptor<Entry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entries = try modelContext.fetch(descriptor)
        return entries.map(EntryDTO.init)
    }

    func fetchByFolder(folderId: UUID) throws -> [EntryDTO] {
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.folderId == folderId },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entries = try modelContext.fetch(descriptor)
        return entries.map(EntryDTO.init)
    }

    func add(dto: EntryDTO) throws {
        let entry = Entry(
            id: dto.id,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            memo: dto.memo,
            imagePath: dto.imagePath,
            thumbPath: dto.thumbPath,
            title: dto.title,
            folderId: dto.folderId,
            imageWidth: dto.imageWidth,
            imageHeight: dto.imageHeight
        )
        modelContext.insert(entry)
        try modelContext.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entry = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entry)
        try modelContext.save()
    }

    func updateMemo(id: UUID, memo: String) throws -> EntryDTO {
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.id == id }
        )
        guard let entry = try modelContext.fetch(descriptor).first else {
            throw EntryStoreError.entryNotFound
        }
        entry.memo = memo
        entry.updatedAt = .now
        try modelContext.save()
        return EntryDTO(from: entry)
    }

    func moveToFolder(entryId: UUID, folderId: UUID?) throws {
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.id == entryId }
        )
        guard let entry = try modelContext.fetch(descriptor).first else {
            throw EntryStoreError.entryNotFound
        }
        entry.folderId = folderId
        entry.updatedAt = .now
        try modelContext.save()
    }

    func migrateImageDimensions() throws {
        // 이미 마이그레이션 완료되었는지 확인
        let key = "didMigrateImageDimensions_v1"
        if UserDefaults.standard.bool(forKey: key) {
            return
        }

        // 크기 정보가 없는 Entry들을 찾아서 업데이트
        let descriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.imageWidth == nil || $0.imageHeight == nil }
        )
        let entries = try modelContext.fetch(descriptor)

        for entry in entries {
            // 이미지 파일에서 크기 정보 추출
            if let size = Self.getImageSize(for: entry.imagePath) {
                entry.imageWidth = Double(size.width)
                entry.imageHeight = Double(size.height)
            }
        }

        try modelContext.save()

        // 마이그레이션 완료 표시
        UserDefaults.standard.set(true, forKey: key)
    }

    private static func getImageSize(for path: String) -> CGSize? {
        // 이미지 파일 경로 확인
        guard let fileURL = try? resolveImageURL(for: path) else { return nil }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }

        // 이미지 크기 추출 (메모리에 전체 이미지를 로드하지 않고 메타데이터만 읽음)
        guard let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }

        return CGSize(width: width, height: height)
    }

    private static func resolveImageURL(for path: String) throws -> URL {
        let base = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        if path.hasPrefix("thumb_") {
            let dir = base.appendingPathComponent("thumbnails", isDirectory: true)
            return dir.appendingPathComponent(path)
        } else {
            let dir = base.appendingPathComponent("images", isDirectory: true)
            return dir.appendingPathComponent(path)
        }
    }
}

// MARK: - Error

enum EntryStoreError: LocalizedError {
    case entryNotFound

    var errorDescription: String? {
        switch self {
        case .entryNotFound:
            return "항목을 찾을 수 없습니다."
        }
    }
}

// MARK: - DependencyKey

extension EntryStoreClient: DependencyKey {
    static let liveValue: EntryStoreClient = {
        let actor = EntryModelActor(modelContainer: ModelContainerProvider.shared)

        return Self(
            fetchAll: {
                try await actor.fetchAll()
            },
            fetchByFolder: { folderId in
                try await actor.fetchByFolder(folderId: folderId)
            },
            add: { dto in
                try await actor.add(dto: dto)
            },
            delete: { id in
                try await actor.delete(id: id)
            },
            updateMemo: { id, memo in
                try await actor.updateMemo(id: id, memo: memo)
            },
            moveToFolder: { entryId, folderId in
                try await actor.moveToFolder(entryId: entryId, folderId: folderId)
            },
            migrateImageDimensions: {
                try await actor.migrateImageDimensions()
            }
        )
    }()

    static let testValue = Self(
        fetchAll: { [] },
        fetchByFolder: { _ in [] },
        add: { _ in },
        delete: { _ in },
        updateMemo: { _, _ in
            EntryDTO(id: UUID(), createdAt: .now, updatedAt: .now, memo: "", imagePath: "", thumbPath: nil, title: nil, folderId: nil, imageWidth: nil, imageHeight: nil)
        },
        moveToFolder: { _, _ in },
        migrateImageDimensions: { }
    )
}

// MARK: - DependencyValues

extension DependencyValues {
    var entryStoreClient: EntryStoreClient {
        get { self[EntryStoreClient.self] }
        set { self[EntryStoreClient.self] = newValue }
    }
}
