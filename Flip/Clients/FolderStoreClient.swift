//
//  FolderStoreClient.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import SwiftData
import Dependencies

// MARK: - FolderDTO

struct FolderDTO: Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let createdAt: Date
    let sortOrder: Int
}

extension FolderDTO {
    init(from folder: Folder) {
        self.id = folder.id
        self.name = folder.name
        self.createdAt = folder.createdAt
        self.sortOrder = folder.sortOrder
    }
}

// MARK: - Interface

struct FolderStoreClient {
    var fetchAll: @Sendable () async throws -> [FolderDTO]
    var add: @Sendable (_ name: String) async throws -> FolderDTO
    var rename: @Sendable (_ id: UUID, _ newName: String) async throws -> FolderDTO
    var delete: @Sendable (_ id: UUID) async throws -> Void
}

// MARK: - ModelActor

@ModelActor
actor FolderModelActor {
    func fetchAll() throws -> [FolderDTO] {
        let descriptor = FetchDescriptor<Folder>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        let folders = try modelContext.fetch(descriptor)
        return folders.map(FolderDTO.init)
    }

    func add(name: String) throws -> FolderDTO {
        let maxOrder = try fetchMaxSortOrder()
        let folder = Folder(name: name, sortOrder: maxOrder + 1)
        modelContext.insert(folder)
        try modelContext.save()
        return FolderDTO(from: folder)
    }

    func rename(id: UUID, newName: String) throws -> FolderDTO {
        let descriptor = FetchDescriptor<Folder>(
            predicate: #Predicate { $0.id == id }
        )
        guard let folder = try modelContext.fetch(descriptor).first else {
            throw FolderStoreError.folderNotFound
        }
        folder.name = newName
        try modelContext.save()
        return FolderDTO(from: folder)
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<Folder>(
            predicate: #Predicate { $0.id == id }
        )
        guard let folder = try modelContext.fetch(descriptor).first else { return }

        // 폴더 내 Entry들의 folderId를 nil로 초기화
        let entryDescriptor = FetchDescriptor<Entry>(
            predicate: #Predicate { $0.folderId == id }
        )
        let entries = try modelContext.fetch(entryDescriptor)
        for entry in entries {
            entry.folderId = nil
        }

        modelContext.delete(folder)
        try modelContext.save()
    }

    private func fetchMaxSortOrder() throws -> Int {
        let descriptor = FetchDescriptor<Folder>(
            sortBy: [SortDescriptor(\.sortOrder, order: .reverse)]
        )
        let folders = try modelContext.fetch(descriptor)
        return folders.first?.sortOrder ?? 0
    }
}

// MARK: - Error

enum FolderStoreError: LocalizedError {
    case folderNotFound

    var errorDescription: String? {
        switch self {
        case .folderNotFound:
            return "폴더를 찾을 수 없습니다."
        }
    }
}

// MARK: - DependencyKey

extension FolderStoreClient: DependencyKey {
    static let liveValue: FolderStoreClient = {
        let actor = FolderModelActor(modelContainer: ModelContainerProvider.shared)

        return Self(
            fetchAll: {
                try await actor.fetchAll()
            },
            add: { name in
                try await actor.add(name: name)
            },
            rename: { id, newName in
                try await actor.rename(id: id, newName: newName)
            },
            delete: { id in
                try await actor.delete(id: id)
            }
        )
    }()

    static let testValue = Self(
        fetchAll: { [] },
        add: { name in FolderDTO(id: UUID(), name: name, createdAt: .now, sortOrder: 0) },
        rename: { _, name in FolderDTO(id: UUID(), name: name, createdAt: .now, sortOrder: 0) },
        delete: { _ in }
    )
}

// MARK: - DependencyValues

extension DependencyValues {
    var folderStoreClient: FolderStoreClient {
        get { self[FolderStoreClient.self] }
        set { self[FolderStoreClient.self] = newValue }
    }
}
