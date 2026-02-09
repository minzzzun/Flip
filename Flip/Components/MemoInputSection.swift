//
//  MemoInputSection.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI

struct MemoInputSection: View {
    @Binding var memo: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("메모")
                .font(.headline)

            TextEditor(text: $memo)
                .frame(minHeight: 120)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .scrollContentBackground(.hidden)
        }
    }
}
