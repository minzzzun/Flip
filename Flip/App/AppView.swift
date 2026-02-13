//
//  AppView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            GalleryView(store: store.scope(state: \.gallery, action: \.gallery))
        } destination: { store in
            switch store.case {
            case let .detail(detailStore):
                EntryDetailView(store: detailStore)
            }
        }
        .fullScreenCover(
            item: $store.scope(state: \.onboarding, action: \.onboarding)
        ) { onboardingStore in
            OnboardingView(store: onboardingStore)
        }
    }
}
