//
//  EntryStoreClient.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import SwiftData
import Dependencies

struct EntryStoreClient {
    var fetchAll: @Sendable () async throws -> [EntryDTO]
    var fetchByFolder: @Sendable (_ folderId: UUID) async throws -> [EntryDTO]
    var add: @Sendable (_ dto: EntryDTO) async throws -> Void
    var delete: @Sendable (_ id: UUID) async throws -> Void
    var updateMemo: @Sendable (_ id: UUID, _ memo: String) async throws -> EntryDTO
    var moveToFolder: @Sendable (_ entryId: UUID, _ folderId: UUID?) async throws -> Void
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
            folderId: dto.folderId
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
            }
        )
    }()

    static let testValue = Self(
        fetchAll: { [] },
        fetchByFolder: { _ in [] },
        add: { _ in },
        delete: { _ in },
        updateMemo: { _, _ in
            EntryDTO(id: UUID(), createdAt: .now, updatedAt: .now, memo: "", imagePath: "", thumbPath: nil, title: nil, folderId: nil)
        },
        moveToFolder: { _, _ in }
    )
}

// MARK: - DependencyValues

extension DependencyValues {
    var entryStoreClient: EntryStoreClient {
        get { self[EntryStoreClient.self] }
        set { self[EntryStoreClient.self] = newValue }
    }
}
