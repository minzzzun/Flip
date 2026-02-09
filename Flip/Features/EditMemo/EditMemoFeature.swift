//
//  EditMemoFeature.swift
//  Flip
//
//  Created by 김민준 on 2/2/26.
//

import Foundation
import ComposableArchitecture

@Reducer
struct EditMemoFeature {
    @ObservableState
    struct State: Equatable {
        let entryId: UUID
        var memo: String
        var isSaving = false
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case saveResponse(Result<EntryDTO, Error>)
        case saveDone(EntryDTO)
        case cancelButtonTapped
        case alert(PresentationAction<Alert>)

        @CasePathable
        enum Alert: Equatable {}
    }

    @Dependency(\.entryStoreClient) var entryStoreClient
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State,Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .saveButtonTapped:
                state.isSaving = true
                let id = state.entryId
                let memo = state.memo
                return .run { send in
                    let result = await Result {
                        try await entryStoreClient.updateMemo(id, memo)
                    }
                    await send(.saveResponse(result))
                }

            case let .saveResponse(.success(updatedEntry)):
                state.isSaving = false
                return .send(.saveDone(updatedEntry))

            case let .saveResponse(.failure(error)):
                state.isSaving = false
                state.alert = AlertState {
                    TextState("저장 실패")
                } actions: {
                    ButtonState(role: .cancel) {
                        TextState("확인")
                    }
                } message: {
                    TextState(error.localizedDescription)
                }
                return .none

            case .saveDone:
                // Handled by parent (EntryDetailFeature)
                return .none

            case .cancelButtonTapped:
                return .run { _ in await dismiss() }

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
