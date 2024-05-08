//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

private struct CallEndedViewModifier<Subview: View>: ViewModifier {

    private final class CallEndedViewModifierState: ObservableObject {
        @Published var call: Call?
        @Published var isPresentingSubview: Bool
        @Published var maxParticipantsCount: Int

        init(
            call: Call? = nil,
            isPresentingSubview: Bool = false,
            maxParticipantsCount: Int = 0
        ) {
            self.call = call
            self.isPresentingSubview = isPresentingSubview
            self.maxParticipantsCount = maxParticipantsCount
        }
    }

    @Injected(\.streamVideo) private var streamVideo

    private var subviewProvider: (Call?, @escaping () -> Void) -> Subview

    @StateObject private var state: CallEndedViewModifierState = .init()

    init(
        @ViewBuilder subviewProvider: @escaping (Call?, @escaping () -> Void) -> Subview
    ) {
        self.subviewProvider = subviewProvider
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $state.isPresentingSubview) {
                subviewProvider(state.call) {
                    state.call = nil
                    state.isPresentingSubview = false
                }
            }
            .onReceive(streamVideo.state.$activeCall.removeDuplicates { $0?.cId != $1?.cId }) { call in
                switch (call, state.call, state.isPresentingSubview) {
                case (nil, let activeCall, false) where activeCall != nil && state.maxParticipantsCount > 1:
                    /// The following presentation criteria are required:
                    /// - The activeCall was ended.
                    /// - Participants, during call's duration, grew to more than one.
                    state.isPresentingSubview = true

                case let (newActiveCall, activeCall, _) where newActiveCall != nil && activeCall != nil:
                    /// The activeCall was replaced with another call. We should not present the
                    /// subview. We will also hide any modals if any is visible.
                    state.call = newActiveCall
                    state.isPresentingSubview = false
                    state.maxParticipantsCount = 0

                case (let newActiveCall, nil, _) where newActiveCall != nil:
                    /// The activeCall was replaced with another call. We should not present the
                    /// subview. We will also hide any modals if any is visible.
                    state.call = newActiveCall
                    state.isPresentingSubview = false
                    state.maxParticipantsCount = 0

                default:
                    /// For every other case we won't perform any action.
                    log
                        .debug(
                            "CallEnded view modifier received newValue:\(call?.cId ?? "nil") oldValue:\(state.call?.cId ?? "nil") isPresentingSubview:\(state.isPresentingSubview) maxParticipantsCount:\(state.maxParticipantsCount). No action is required."
                        )
                }
            }
            .onReceive(streamVideo.state.activeCall?.state.$participants.map(\.count)) {
                /// Every time participants update, we store the maximum number of participants in
                /// the call (during call's duration).
                state.maxParticipantsCount = max(state.maxParticipantsCount, $0)
            }
    }
}

extension View {

    /// A viewModifier that observes callState from StreamVideo. Once the following criteria are being
    /// fulfilled, presents a modal with the provided content.
    /// Activation criteria:
    /// - Active call was ended.
    /// - Participants, during call's duration, grew to more than one.
    ///
    /// - Parameter content: A viewBuilder that returns the modal's content. The viewModifier
    /// will provide a dismiss closure that can be called from the content to close the modal.
    @ViewBuilder
    public func onCallEnded(
        @ViewBuilder _ content: @escaping (Call?, @escaping () -> Void) -> some View
    ) -> some View {
        modifier(
            CallEndedViewModifier(
                subviewProvider: content
            )
        )
    }
}
