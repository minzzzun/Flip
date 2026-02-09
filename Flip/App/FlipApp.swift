//
//  FlipApp.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct FlipApp: App {
    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: FlipApp.store)
        }
    }
}
