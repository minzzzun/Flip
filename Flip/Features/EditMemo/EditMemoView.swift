//
//  EditMemoView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct EditMemoView: View {
    @Bindable var store: StoreOf<EditMemoFeature>

    var body: some View {
        ScrollView {
            MemoInputSection(memo: $store.memo)
                .padding()
        }
        .navigationTitle("메모 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("취소") {
                    store.send(.cancelButtonTapped)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if store.isSaving {
                    ProgressView()
                } else {
                    Button("저장") {
                        store.send(.saveButtonTapped)
                    }
                }
            }
        }
        .interactiveDismissDisabled(store.isSaving)
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
