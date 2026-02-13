//
//  OnboardingView.swift
//  Flip
//
//  Created by 김민준 on 2/13/26.
//

import SwiftUI
import ComposableArchitecture

// MARK: - Page Model

private struct OnboardingPage {
    let symbol: String
    let title: String
    let description: String
}

private let pages: [OnboardingPage] = [
    OnboardingPage(
        symbol: "photo.stack",
        title: "Flip에 오신 것을 환영합니다",
        description: "사진과 메모로 소중한 순간을 기록하세요"
    ),
    OnboardingPage(
        symbol: "rectangle.stack.fill",
        title: "아름다운 갤러리",
        description: "모든 기록을 한눈에 볼 수 있어요.\n폴더로 체계적으로 정리하세요"
    ),
    OnboardingPage(
        symbol: "hand.tap.fill",
        title: "플립 카드",
        description: "카드를 탭하면 3D 애니메이션으로 뒤집혀요.\n앞면엔 사진, 뒷면엔 메모!"
    ),
    OnboardingPage(
        symbol: "plus.circle.fill",
        title: "지금 시작하세요",
        description: "+ 버튼으로 첫 번째 기억을 남겨보세요"
    ),
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        ZStack(alignment: .top) {
            // 건너뛰기 버튼 (마지막 페이지 제외)
            if store.currentPage < store.totalPages - 1 {
                HStack {
                    Spacer()
                    Button("건너뛰기") {
                        store.send(.skipTapped)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
            }

            VStack(spacing: 0) {
                // 페이지 콘텐츠
                TabView(selection: Binding(
                    get: { store.currentPage },
                    set: { _ in } // 스와이프 조작 비활성화, 버튼으로만 이동
                )) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .animation(.easeInOut(duration: 0.3), value: store.currentPage)

                // 하단 버튼
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .padding(.top, 8)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom Button

    @ViewBuilder
    private var bottomButton: some View {
        let isLastPage = store.currentPage == store.totalPages - 1

        Button {
            if isLastPage {
                store.send(.startTapped)
            } else {
                store.send(.nextTapped)
            }
        } label: {
            Text(isLastPage ? "시작하기" : "다음")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .animation(.easeInOut(duration: 0.2), value: isLastPage)
    }
}

// MARK: - OnboardingPageView

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: page.symbol)
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)

                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}
