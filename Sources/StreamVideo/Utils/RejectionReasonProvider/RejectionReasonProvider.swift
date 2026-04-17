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

    /// Determines whether a ringing call was already handled elsewhere and, if
    /// so, returns the backend leave reason that should be used locally.
    ///
    /// - Parameter callState: The latest backend state for the ringing call.
    /// - Returns: A backend leave reason, or `nil` when the device should keep
    ///   ringing locally.
    func reason(callState: GetCallResponse) -> String?
}

public extension RejectionReasonProviding {

    /// Default no-op implementation to preserve source compatibility for
    /// existing custom providers that do not yet reason about handled calls.
    func reason(callState: GetCallResponse) -> String? {
        _ = callState
        return nil
    }
}

/// A provider that determines the rejection reason for a call based on its state.
final class StreamRejectionReasonProvider: RejectionReasonProviding, @unchecked Sendable {

    /// Backend leave reasons for incoming ringing calls that were already
    /// handled on another device or by another participant.
    enum HandledCallReason: String {
        /// Used when CallKit needs a handled-call reason before a
        /// `StreamVideo` client is configured on the service/provider.
        case notConfigured = "not-configured"

        /// Used when reporting the incoming call fails before the local device
        /// can continue the ringing flow.
        case reportCallFailed = "report-call-failed"

        /// Used when a backend `call.ended` event dismisses the local ringing
        /// flow before the user answers.
        case callEventReceived = "call.ended event received"

        /// Used when the latest backend call state already marks the call as
        /// ended before CallKit starts ringing locally.
        case callHasEnded = "call-has-ended"

        /// Used when the local SDK already ended the call and CallKit is being
        /// brought back in sync through `CallNotification.callEnded`.
        case callEndedLocally = "call-ended-locally"

        /// Used when the same user already accepted, rejected, or missed the
        /// ringing call on another device.
        case userRespondedElsewhere = "user-responded-elsewhere"

        /// Used when the caller cancels the ringing flow before any other
        /// invitee has accepted the call.
        case creatorRejected = "ring: creator rejected"

        /// Used when every invitee other than the current user and the caller
        /// has already rejected the ringing call.
        case allOtherParticipantsRejected = "ring: everyone rejected"

        /// Used when the configured participant auto-leave policy ends the
        /// active CallKit-managed call.
        case autoLeave = "auto-leave"
    }

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

    /// Returns the backend leave reason for a ringing call that no longer
    /// needs to keep ringing on this device.
    func reason(callState: GetCallResponse) -> String? {
        guard let currentUserId = streamVideo?.user.id else {
            return HandledCallReason.notConfigured.rawValue
        }

        if callHasEnded(callState) {
            return HandledCallReason.callHasEnded.rawValue
        } else if currentUserRespondedElsewhere(callState, currentUserId: currentUserId) {
            return HandledCallReason.userRespondedElsewhere.rawValue
        } else if creatorHungUpAndNoOneElseAccepted(callState) {
            return HandledCallReason.creatorRejected.rawValue
        } else if otherParticipantsRejected(callState, currentUserId: currentUserId) {
            return HandledCallReason.allOtherParticipantsRejected.rawValue
        } else {
            return nil
        }
    }

    // MARK: - Private Helpers

    private func callHasEnded(_ callState: GetCallResponse) -> Bool {
        callState.call.endedAt != nil
    }

    private func currentUserRespondedElsewhere(
        _ callState: GetCallResponse,
        currentUserId: String
    ) -> Bool {
        let hasCurrentUserAcceptedElsewhere =
            callState.call.session?.acceptedBy[currentUserId] != nil
        let hasCurrentUserRejectedElsewhere =
            callState.call.session?.rejectedBy[currentUserId] != nil
        let hasCurrentUserMissed =
            callState.call.session?.missedBy[currentUserId] != nil
        return hasCurrentUserAcceptedElsewhere
            || hasCurrentUserRejectedElsewhere
            || hasCurrentUserMissed
    }

    private func creatorHungUpAndNoOneElseAccepted(
        _ callState: GetCallResponse
    ) -> Bool {
        let creatorId = callState.call.createdBy.id

        guard
            callState.call.session?.rejectedBy[creatorId] != nil
        else {
            return false
        }

        let otherAcceptedParticipants = Set(
            (callState.call.session?.acceptedBy ?? [:]).keys.filter { $0 != creatorId }
        )

        guard otherAcceptedParticipants.isEmpty else {
            return false
        }

        return true
    }

    private func otherParticipantsRejected(
        _ callState: GetCallResponse,
        currentUserId: String
    ) -> Bool {
        let creatorId = callState.call.createdBy.id

        // Only invitees other than the current user and the creator count
        // toward the "everyone else rejected" rule.
        let otherParticipants = Set(
            callState.members
                .map(\.userId)
                .filter { $0 != currentUserId && $0 != creatorId }
        )
        let rejectedOtherParticipants = Set(
            (callState.call.session?.rejectedBy ?? [:])
                .keys
                .filter { $0 != currentUserId && $0 != creatorId }
        )

        guard
            otherParticipants.isEmpty == false,
            otherParticipants.isSubset(of: rejectedOtherParticipants)
        else {
            return false
        }

        return true
    }
}
