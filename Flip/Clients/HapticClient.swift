//
//  HapticClient.swift
//  Flip
//
//  Created by 김민준 on 2/10/26.
//

import UIKit
import Dependencies

struct HapticClient {
    var impact: @Sendable (UIImpactFeedbackGenerator.FeedbackStyle) -> Void
    var selection: @Sendable () -> Void
    var notification: @Sendable (UINotificationFeedbackGenerator.FeedbackType) -> Void
}

// MARK: - DependencyKey

extension HapticClient: DependencyKey {
    static let liveValue = Self(
        impact: { style in
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        },
        selection: {
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        },
        notification: { type in
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
        }
    )

    static let testValue = Self(
        impact: { _ in },
        selection: { },
        notification: { _ in }
    )
}

// MARK: - DependencyValues

extension DependencyValues {
    var hapticClient: HapticClient {
        get { self[HapticClient.self] }
        set { self[HapticClient.self] = newValue }
    }
}
