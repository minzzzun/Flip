//
//  FlipCardView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct FlipCardView<Front: View, Back: View>: View {
    let isFlipped: Bool
    let onTap: () -> Void
    @ViewBuilder let front: () -> Front
    @ViewBuilder let back: () -> Back

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if reduceMotion {
                // Reduce Motion: fade 전환
                if isFlipped {
                    back()
                        .transition(.opacity)
                } else {
                    front()
                        .transition(.opacity)
                }
            } else {
                // 3D Flip 애니메이션
                front()
                    .rotation3DEffect(
                        .degrees(isFlipped ? 180 : 0),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .opacity(isFlipped ? 0 : 1)

                back()
                    .rotation3DEffect(
                        .degrees(isFlipped ? 0 : -180),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .opacity(isFlipped ? 1 : 0)
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.3) : .easeInOut(duration: 0.5), value: isFlipped)
        .onTapGesture {
            onTap()
        }
    }
}
