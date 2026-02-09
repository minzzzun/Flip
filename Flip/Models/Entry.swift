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

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date = .now,
        memo: String = "",
        imagePath: String,
        thumbPath: String? = nil,
        title: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.memo = memo
        self.imagePath = imagePath
        self.thumbPath = thumbPath
        self.title = title
    }
}
