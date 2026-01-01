//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol that provides a method to determine the rejection reason for a call.
public protocol RejectionReasonProviding: Sendable {

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
    func reason(for callCid: String, ringTimeout: Bool) async -> String?
}

/// A provider that determines the rejection reason for a call based on its state.
final class StreamRejectionReasonProvider: RejectionReasonProviding, @unchecked Sendable {

    /// The stream video associated with this provider.
    private nonisolated(unsafe) weak var streamVideo: StreamVideo?

    /// A container for managing cancellable subscriptions.
    private let disposableBag: DisposableBag = .init()

    init(_ streamVideo: StreamVideo) {
        self.streamVideo = streamVideo
    }

    // MARK: - RejectionReasonProviding

    func reason(
        for callCid: String,
        ringTimeout: Bool
    ) async -> String? {
        let activeCall = streamVideo?.state.activeCall

        guard
            let rejectingCall = streamVideo?.state.ringingCall,
            rejectingCall.cId == callCid
        else {
            return nil
        }

        let isUserBusy = activeCall != nil
        let userId = streamVideo?.user.id
        let isUserRejectingOutgoingCall = await Task(disposableBag: disposableBag) { @MainActor in
            rejectingCall.state.createdBy?.id == userId
        }.value

        if isUserBusy {
            return RejectCallRequest.Reason.busy
        } else if isUserRejectingOutgoingCall {
            return RejectCallRequest.Reason.cancel
        } else {
            return ringTimeout
                ? RejectCallRequest.Reason.timeout
                : RejectCallRequest.Reason.decline
        }
    }
}
