//
//  EntryDetailView.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import SwiftUI
import ComposableArchitecture

struct EntryDetailView: View {
    @Bindable var store: StoreOf<EntryDetailFeature>

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 16) {
                    FlipCardView(
                        isFlipped: store.isFlipped,
                        onTap: {
                            store.send(.cardTapped)
                        },
                        front: {
                            DetailFrontView(
                                image: store.image,
                                isLoading: store.isLoadingImage,
                                maxWidth: geometry.size.width - 32
                            )
                        },
                        back: {
                            DetailBackView(
                                memo: store.entry.memo,
                                createdAt: store.entry.createdAt,
                                maxWidth: geometry.size.width - 32
                            )
                        }
                    )
                    .frame(minHeight: geometry.size.width * 1.2)

                    Text("탭하여 뒤집기")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationTitle("상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    store.send(.deleteButtonTapped)
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}
