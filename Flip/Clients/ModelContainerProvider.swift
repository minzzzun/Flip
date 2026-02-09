//
//  ModelContainerProvider.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import SwiftData

enum ModelContainerProvider {
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(for: Entry.self, Folder.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()
}
