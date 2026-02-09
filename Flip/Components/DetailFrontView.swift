//
//  DetailFrontView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct DetailFrontView: View {
    let image: UIImage?
    let isLoading: Bool
    let maxWidth: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                Color.gray.opacity(0.1)
                    .overlay { ProgressView() }
            } else {
                Color.gray.opacity(0.1)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.tertiary)
                    }
            }
        }
        .frame(maxWidth: maxWidth)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
