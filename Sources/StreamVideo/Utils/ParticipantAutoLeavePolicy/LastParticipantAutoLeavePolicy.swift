//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A policy that triggers an action when during a ringing flow call (incoming or outgoing) there is only one
/// participant left in a call, after having previously had multiple participants.
public final class LastParticipantAutoLeavePolicy: ParticipantAutoLeavePolicy {

    /// Injected dependency for accessing the stream video service.
    @Injected(\.streamVideo) private var streamVideo

    /// Subscription for observing changes to the ringing call.
    private var ringingCallCancellable: AnyCancellable?

    /// The identifier of the latest ringing call.
    private var latestRingingCallCid: String?

    /// Subscription for observing changes to the active call.
    private var activeCallCancellable: AnyCancellable?

    /// The current active call.
    private var activeCall: Call? {
        didSet { didUpdateCall(activeCall, oldValue: oldValue) }
    }

    /// Subscription for observing changes to the call participants.
    private var callParticipantsObservation: AnyCancellable?

    /// The maximum number of participants observed in the current call.
    private var maxAggregatedParticipantsCount: Int = 0

    /// The current number of participants in the call.
    private var currentParticipantsCount: Int = 0 {
        didSet {
            maxAggregatedParticipantsCount = max(maxAggregatedParticipantsCount, currentParticipantsCount)
            let currentCount = currentParticipantsCount
            let maxCount = maxAggregatedParticipantsCount
            // Check if the policy trigger conditions are met.
            Task { @MainActor in
                checkTrigger(currentCount: currentCount, maxCount: maxCount)
            }
        }
    }

    /// A closure that will be called once the rules evaluated in the policy have been triggered.
    public var onPolicyTriggered: (() -> Void)?

    /// Initializes a new instance of `LastParticipantAutoLeavePolicy`.
    public init() {
        // Observing changes to the ringing call state.
        ringingCallCancellable = streamVideo
            .state
            .$ringingCall
            .compactMap(\.?.cId)
            .assign(to: \.latestRingingCallCid, onWeak: self)

        // Observing changes to the active call state.
        activeCallCancellable = streamVideo
            .state
            .$activeCall
            .assign(to: \.activeCall, onWeak: self)
    }

    /// The current call being observed.
    private var call: Call? {
        didSet {
            // Handle updates to the current call.
            Task { @MainActor in
                didUpdateCall(call, oldValue: oldValue)
            }
        }
    }

    // MARK: - Private API

    /// Handles updates to the current call.
    /// - Parameters:
    ///   - call: The new call instance.
    ///   - oldValue: The previous call instance.
    private func didUpdateCall(_ call: Call?, oldValue: Call?) {
        guard call?.cId != oldValue?.cId else { return }

        // Cancel any existing participant observations.
        callParticipantsObservation?.cancel()
        callParticipantsObservation = nil
        maxAggregatedParticipantsCount = 0
        currentParticipantsCount = 0

        // Start call observation only if the activeCall is an incoming or
        // outgoing call.
        guard let call, call.cId == latestRingingCallCid else { return }

        // Observe changes to the participants map in the new call.
        Task { @MainActor in
            callParticipantsObservation = call
                .state
                .$participantsMap
                .map(\.count)
                .assign(to: \.currentParticipantsCount, onWeak: self)
        }
    }

    /// Checks if the policy conditions are met to trigger the action.
    /// - Parameters:
    ///   - currentCount: The current number of participants in the call.
    ///   - maxCount: The maximum number of participants that have been in the call.
    @MainActor
    private func checkTrigger(currentCount: Int, maxCount: Int) {
        guard let activeCall else { return }

        // Conditions to trigger the policy: single participant and previously
        // had more than one participant.
        guard currentCount == 1, maxCount > 1 else {
            log.debug(
                """
                Participants updated without triggering \(type(of: self)).
                CallCid: \(activeCall.cId)
                Participants count: \(currentCount)
                Max Participants count: \(maxCount)
                """
            )
            return
        }

        // Ensure the session has been accepted by someone.
        guard
            activeCall.state.session?.acceptedBy.isEmpty == false
        else {
            log.debug(
                """
                Participants updated without triggering \(type(of: self)).
                CallCid: \(activeCall.cId)
                Participants count: \(currentCount)
                Max Participants count: \(maxCount)
                Session acceptedBy: \(String(describing: activeCall.state.session?.acceptedBy))
                """
            )
            return
        }

        // Log the trigger and execute the closure.
        log.debug(
            """
            Participants updated triggering \(type(of: self)).
            CallCid: \(activeCall.cId)
            Participants count: \(currentCount)
            Max Participants count: \(maxCount)
            Session acceptedBy: \(String(describing: activeCall.state.session?.acceptedBy))
            """
        )
        onPolicyTriggered?()
    }
}
