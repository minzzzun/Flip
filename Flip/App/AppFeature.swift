//
//  AppFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct AppFeature {
    @ObservableState
    struct State {
        var gallery = GalleryFeature.State()
        var path = StackState<Path.State>()

        @Presents var onboarding: OnboardingFeature.State?

        init() {
            let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
            self.onboarding = hasSeenOnboarding ? nil : OnboardingFeature.State()
        }
    }

    enum Action {
        case gallery(GalleryFeature.Action)
        case path(StackActionOf<Path>)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case onboardingDismissed
    }

    @Reducer
    enum Path {
        case detail(EntryDetailFeature)
    }

    var body: some Reducer<State, Action>  {
        Scope(state: \.gallery, action: \.gallery) {
            GalleryFeature()
        }

        Reduce { state, action in
            switch action {
            case let .gallery(.entryTapped(entry)):
                state.path.append(.detail(EntryDetailFeature.State(entry: entry)))
                return .none

            case .path(.element(_, action: .detail(.popDetail))):
                // Detail에서 삭제 후 pop -> Gallery 갱신
                return .send(.gallery(.onAppear))

            case .gallery, .path:
                return .none

            case .onboarding(.presented(.delegate(.onboardingCompleted))):
                state.onboarding = nil
                return .none

            case .onboarding:
                return .none

            case .onboardingDismissed:
                state.onboarding = nil
                return .none
            }
        }
        .forEach(\.path, action: \.path)
        .ifLet(\.$onboarding, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}
