//
//  WaterfallLayoutHelper.swift
//  Flip
//
//  Created by 김민준 on 2/9/26.
//

import SwiftUI

enum WaterfallLayoutHelper {
    /// 화면 크기에 따라 최적의 열 개수를 반환
    /// - iPhone: 2열
    /// - iPad (portrait): 3열
    /// - iPad (landscape): 4열
    static func calculateNumberOfColumns(for width: CGFloat) -> Int {
        if width < 600 {
            // iPhone, small screens
            return 2
        } else if width < 900 {
            // iPad portrait, medium screens
            return 3
        } else {
            // iPad landscape, large screens
            return 4
        }
    }
}
