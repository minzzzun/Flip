//
//  FABButton.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct FABButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Circle().fill(Color.accentColor))
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        }
    }
}
