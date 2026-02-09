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
    var add: @Sendable (_ dto: EntryDTO) async throws -> Void
    var delete: @Sendable (_ id: UUID) async throws -> Void
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

    func add(dto: EntryDTO) throws {
        let entry = Entry(
            id: dto.id,
            createdAt: dto.createdAt,
            updatedAt: dto.updatedAt,
            memo: dto.memo,
            imagePath: dto.imagePath,
            thumbPath: dto.thumbPath,
            title: dto.title
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
}

// MARK: - DependencyKey

extension EntryStoreClient: DependencyKey {
    static let liveValue: EntryStoreClient = {
        let container: ModelContainer = {
            do {
                return try ModelContainer(for: Entry.self)
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }()

        let actor = EntryModelActor(modelContainer: container)

        return Self(
            fetchAll: {
                try await actor.fetchAll()
            },
            add: { dto in
                try await actor.add(dto: dto)
            },
            delete: { id in
                try await actor.delete(id: id)
            }
        )
    }()

    static let testValue = Self(
        fetchAll: { [] },
        add: { _ in },
        delete: { _ in }
    )
}

// MARK: - DependencyValues

extension DependencyValues {
    var entryStoreClient: EntryStoreClient {
        get { self[EntryStoreClient.self] }
        set { self[EntryStoreClient.self] = newValue }
    }
}
