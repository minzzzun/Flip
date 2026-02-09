//
//  GalleryEmptyStateView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct GalleryEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("아직 기록이 없습니다")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("+ 버튼을 눌러 첫 번째 기록을 추가해보세요")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
    }
}
