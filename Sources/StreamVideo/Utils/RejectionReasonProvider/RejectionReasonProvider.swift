//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that provides a method to determine the rejection reason for a call.
public protocol RejectionReasonProviding {

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
    func reason(for callCid: String, ringTimeout: Bool) -> String?
}

/// A provider that determines the rejection reason for a call based on its state.
final class StreamRejectionReasonProvider: RejectionReasonProviding {

    /// The stream video associated with this provider.
    private weak var streamVideo: StreamVideo?

    /// A container for managing cancellable subscriptions.
    private let cancellables: DisposableBag = .init()

    init(_ streamVideo: StreamVideo) {
        self.streamVideo = streamVideo
    }

    // MARK: - RejectionReasonProviding

    @MainActor
    func reason(
        for callCid: String,
        ringTimeout: Bool
    ) -> String? {
        let activeCall = streamVideo?.state.activeCall

        guard
            let rejectingCall = streamVideo?.state.ringingCall,
            rejectingCall.cId == callCid
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
}
