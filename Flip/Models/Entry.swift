//
//  Entry.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import SwiftData

@Model
final class Entry {
    @Attribute(.unique)
    var id: UUID

    var createdAt: Date
    var updatedAt: Date
    var memo: String
    var imagePath: String
    var thumbPath: String?
    var title: String?
    var folderId: UUID?
    var imageWidth: Double?
    var imageHeight: Double?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        memo: String = "",
        imagePath: String,
        thumbPath: String? = nil,
        title: String? = nil,
        folderId: UUID? = nil,
        imageWidth: Double? = nil,
        imageHeight: Double? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.memo = memo
        self.imagePath = imagePath
        self.thumbPath = thumbPath
        self.title = title
        self.folderId = folderId
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }
}
