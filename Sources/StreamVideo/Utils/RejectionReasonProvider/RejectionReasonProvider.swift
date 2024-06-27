//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that provides a method to determine the rejection reason for a call.
public protocol RejectionReasonProviding {

    /// The stream video associated with this provider.
    var streamVideo: StreamVideo? { get set }

    /// Determines the rejection reason for a call with the specified call ID.
    ///
    /// - Parameters:
    ///   - callCid: The call ID to evaluate.
    ///   - ringTimeout: Informs the provider that the rejection is because of the ringing call timeout.
    ///
    /// - Returns: A string representing the rejection reason, or `nil` if there is no reason to reject
    /// the call.
    ///
    /// - Note: ``ringTimeout`` being true, has an effect **only** when it's set  from the side of
    /// the caller when the callee doesn't reply the ringing call in the amount of time set on the dashboard.
    func rejectionReason(for callCid: String, ringTimeout: Bool) -> String?
}

/// A provider that determines the rejection reason for a call based on its state.
final class StreamRejectionReasonProvider: RejectionReasonProviding {

    /// The stream video associated with this provider.
    var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    /// The currently active call, if any.
    private weak var activeCall: Call?

    /// The currently ringing call, if any.
    private weak var ringingCall: Call?

    /// A container for managing cancellable subscriptions.
    private let cancellables: DisposableBag = .init()

    // MARK: - RejectionReasonProviding

    @MainActor
    func rejectionReason(
        for callCid: String,
        ringTimeout: Bool
    ) -> String? {
        guard
            ringingCall?.cId == callCid,
            let rejectingCall = ringingCall
        else {
            return nil
        }

        let isUserBusy = activeCall != nil
        let isUserRejectingOutgoingCall = rejectingCall.state.createdBy?.id == streamVideo?.user.id

        if isUserBusy {
            return RejectCallRequest.Reason.busy
        } else if isUserRejectingOutgoingCall {
            return ringTimeout
                ? RejectCallRequest.Reason.timeout
                : RejectCallRequest.Reason.cancel
        } else {
            return RejectCallRequest.Reason.decline
        }
    }

    // MARK: - Private helpers

    /// Updates the provider with the new stream video and sets up subscriptions to its state.
    ///
    /// - Parameter streamVideo: The new stream video to associate with this provider.
    private func didUpdate(_ streamVideo: StreamVideo?) {
        cancellables.removeAll()
        guard let streamVideo else { return }

        streamVideo
            .state
            .$activeCall
            .assign(to: \.activeCall, onWeak: self)
            .store(in: cancellables)

        streamVideo
            .state
            .$ringingCall
            .assign(to: \.ringingCall, onWeak: self)
            .store(in: cancellables)
    }
}

enum RejectionReasonProviderKey: InjectionKey {
    static var currentValue: RejectionReasonProviding = StreamRejectionReasonProvider()
}

extension InjectedValues {
    public var rejectionReasonProvider: RejectionReasonProviding {
        get { Self[RejectionReasonProviderKey.self] }
        set { Self[RejectionReasonProviderKey.self] = newValue }
    }
}
