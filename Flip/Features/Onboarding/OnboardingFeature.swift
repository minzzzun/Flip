//
//  OnboardingFeature.swift
//  Flip
//
//  Created by 김민준 on 2/13/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var currentPage: Int = 0
        let totalPages: Int = 4
    }

    enum Action {
        case nextTapped
        case skipTapped
        case startTapped
        case delegate(Delegate)

        enum Delegate {
            case onboardingCompleted
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .nextTapped:
                if state.currentPage < state.totalPages - 1 {
                    state.currentPage += 1
                }
                return .none

            case .skipTapped:
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                return .send(.delegate(.onboardingCompleted))

            case .startTapped:
                UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                return .send(.delegate(.onboardingCompleted))

            case .delegate:
                return .none
            }
        }
    }
}
