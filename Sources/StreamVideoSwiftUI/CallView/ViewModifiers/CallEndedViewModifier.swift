//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

private final class CallEndedViewModifierViewModel: ObservableObject, @unchecked Sendable {

    @Injected(\.streamVideo) private var streamVideo

    @Published var activeCall: Call?
    @Published var lastCall: Call?
    @Published var isPresentingSubview: Bool = false {
        didSet {
            switch (isPresentingSubview, oldValue) {
            case (false, true):
                // The order matters here as it triggers the publisher on the View
                maxParticipantsCount = 0
                lastCall = nil
                activeCall = nil
            default:
                break
            }
        }
    }

    @Published var maxParticipantsCount: Int = 0

    private var observationCancellable: AnyCancellable?

    init() {
        observationCancellable = streamVideo
            .state
            .$activeCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.activeCall = $0 }
    }
}

@available(iOS 14.0, *)
private struct CallEndedViewModifier<Subview: View>: ViewModifier {

    private var presentationValidator: (Call?) -> Bool
    private var subviewProvider: (Call?, @escaping () -> Void) -> Subview

    @StateObject private var viewModel: CallEndedViewModifierViewModel

    init(
        presentationValidator: @escaping (Call?) -> Bool,
        @ViewBuilder subviewProvider: @escaping (Call?, @escaping () -> Void) -> Subview
    ) {
        self.presentationValidator = presentationValidator
        self.subviewProvider = subviewProvider
        _viewModel = .init(wrappedValue: .init())
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isPresentingSubview) {
                subviewProvider(viewModel.lastCall) {
                    viewModel.isPresentingSubview = false
                    viewModel.lastCall = nil
                }
                .onDisappear {
                    viewModel.isPresentingSubview = false
                    viewModel.lastCall = nil
                }
            }
            .onReceive(viewModel.$activeCall.removeDuplicates { $0?.cId == $1?.cId }) { call in
                log.debug(
                    """
                    Call id:\(call?.callId ?? "nil") has ended.
                    LastCall id:\(viewModel.lastCall?.cId ?? "nil")
                    isPresentingSubview: \(viewModel.isPresentingSubview)
                    maxParticipantsCount:\(viewModel.maxParticipantsCount)
                    """
                )

                switch (call, viewModel.lastCall, viewModel.isPresentingSubview) {
                case (nil, let activeCall, false)
                    where activeCall != nil && viewModel
                    .maxParticipantsCount > 1 && presentationValidator(viewModel.lastCall):
                    /// The following presentation criteria are required:
                    /// - The activeCall was ended.
                    /// - Participants, during call's duration, grew to more than one.
                    viewModel.isPresentingSubview = true

                case (nil, _, false):
                    /// If we are not going to present then we clear any data.
                    viewModel.lastCall = nil
                    viewModel.isPresentingSubview = false
                    viewModel.maxParticipantsCount = 0

                case let (newActiveCall, activeCall, _) where newActiveCall != nil && activeCall != nil:
                    /// The activeCall was replaced with another call. We should not present the
                    /// subview. We will also hide any modals if any is visible.
                    viewModel.lastCall = newActiveCall
                    viewModel.isPresentingSubview = false
                    viewModel.maxParticipantsCount = 0

                case (let newActiveCall, nil, _) where newActiveCall != nil:
                    /// A new call has started. We should not present the subview. We will also hide
                    /// any modals if any is visible.
                    viewModel.lastCall = newActiveCall
                    viewModel.isPresentingSubview = false
                    viewModel.maxParticipantsCount = 0

                default:
                    /// For every other case we won't perform any action.
                    break
                }
            }
            .onReceive(viewModel.activeCall?.state.$participants) {
                /// Every time participants update, we store the maximum number of participants in
                /// the call (during call's duration).
                let newMaxParticipantsCount = max(viewModel.maxParticipantsCount, $0.count)
                if newMaxParticipantsCount != viewModel.maxParticipantsCount {
                    log
                        .debug(
                            "CallEnded view modifier updated maxParticipantsCount:\(viewModel.maxParticipantsCount) → \(newMaxParticipantsCount)"
                        )
                    viewModel.maxParticipantsCount = newMaxParticipantsCount
                }
            }
    }
}

@available(iOS, introduced: 13, obsoleted: 14)
private struct CallEndedViewModifier_iOS13<Subview: View>: ViewModifier {

    private var presentationValidator: (Call?) -> Bool
    private var subviewProvider: (Call?, @escaping () -> Void) -> Subview

    @BackportStateObject private var viewModel: CallEndedViewModifierViewModel

    init(
        presentationValidator: @escaping (Call?) -> Bool,
        @ViewBuilder subviewProvider: @escaping (Call?, @escaping () -> Void) -> Subview
    ) {
        self.presentationValidator = presentationValidator
        self.subviewProvider = subviewProvider
        _viewModel = .init(wrappedValue: .init())
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $viewModel.isPresentingSubview) {
                subviewProvider(viewModel.lastCall) {
                    viewModel.lastCall = nil
                    viewModel.isPresentingSubview = false
                }
            }
            .onReceive(viewModel.$activeCall) { call in
                log
                    .debug(
                        "CallEnded view modifier received newValue:\(call?.cId ?? "nil") oldValue:\(viewModel.lastCall?.cId ?? "nil") isPresentingSubview:\(viewModel.isPresentingSubview) maxParticipantsCount:\(viewModel.maxParticipantsCount)."
                    )

                switch (call, viewModel.lastCall, viewModel.isPresentingSubview) {
                case (nil, let activeCall, false)
                    where activeCall != nil && viewModel
                    .maxParticipantsCount > 1 && presentationValidator(viewModel.lastCall):
                    /// The following presentation criteria are required:
                    /// - The activeCall was ended.
                    /// - Participants, during call's duration, grew to more than one.
                    viewModel.isPresentingSubview = true

                case let (newActiveCall, activeCall, _) where newActiveCall != nil && activeCall != nil:
                    /// The activeCall was replaced with another call. We should not present the
                    /// subview. We will also hide any modals if any is visible.
                    viewModel.lastCall = newActiveCall
                    viewModel.isPresentingSubview = false
                    viewModel.maxParticipantsCount = 0

                case (let newActiveCall, nil, _) where newActiveCall != nil:
                    /// The activeCall was replaced with another call. We should not present the
                    /// subview. We will also hide any modals if any is visible.
                    viewModel.lastCall = newActiveCall
                    viewModel.isPresentingSubview = false
                    viewModel.maxParticipantsCount = 0

                default:
                    /// For every other case we won't perform any action.
                    break
                }
            }
            .onReceive(viewModel.activeCall?.state.$participants) {
                /// Every time participants update, we store the maximum number of participants in
                /// the call (during call's duration).
                let newMaxParticipantsCount = max(viewModel.maxParticipantsCount, $0.count)
                if newMaxParticipantsCount != viewModel.maxParticipantsCount {
                    log
                        .debug(
                            "CallEnded view modifier updated maxParticipantsCount:\(viewModel.maxParticipantsCount) → \(newMaxParticipantsCount)"
                        )
                    viewModel.maxParticipantsCount = newMaxParticipantsCount
                }
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
    /// - Parameters:
    ///  - presentationValidator: A closure that can be used to provide additional
    ///  validation rules for presentation. The modifier will inject the last available call when calling.
    ///  - content: A viewBuilder that returns the modal's content. The viewModifier
    /// will provide a dismiss closure that can be called from the content to close the modal.
    @MainActor
    @ViewBuilder
    public func onCallEnded(
        presentationValidator: @escaping (Call?) -> Bool = { _ in true },
        @ViewBuilder _ content: @escaping (Call?, @escaping () -> Void) -> some View
    ) -> some View {
        if #available(iOS 14.0, *) {
            modifier(
                CallEndedViewModifier(
                    presentationValidator: presentationValidator,
                    subviewProvider: content
                )
            )
        } else {
            modifier(
                CallEndedViewModifier_iOS13(
                    presentationValidator: presentationValidator,
                    subviewProvider: content
                )
            )
        }
    }
}
