//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public final class LastParticipantAutoLeavePolicy: ParticipantAutoLeavePolicy {

    @Injected(\.streamVideo) private var streamVideo

    private var ringingCallCancellable: AnyCancellable?
    private var latestRingingCallCid: String?

    private var activeCallCancellable: AnyCancellable?
    private var activeCall: Call? {
        didSet { didUpdateCall(activeCall, oldValue: oldValue) }
    }

    private var callParticipantsObservation: AnyCancellable?
    private var maxAggregatedParticipantsCount: Int = 0
    private var currentParticipantsCount: Int = 0 {
        didSet {
            maxAggregatedParticipantsCount = max(maxAggregatedParticipantsCount, currentParticipantsCount)
            let currentCount = currentParticipantsCount
            let maxCount = maxAggregatedParticipantsCount
            Task { @MainActor in
                checkTrigger(currentCount: currentCount, maxCount: maxCount)
            }
        }
    }

    public var onPolicyTriggered: (() -> Void)?

    public init() {
        ringingCallCancellable = streamVideo
            .state
            .$ringingCall
            .compactMap(\.?.cId)
            .assign(to: \.latestRingingCallCid, onWeak: self)

        activeCallCancellable = streamVideo
            .state
            .$activeCall
            .assign(to: \.activeCall, onWeak: self)
    }

    private var call: Call? {
        didSet {
            Task { @MainActor in
                didUpdateCall(call, oldValue: oldValue)
            }
        }
    }

    // MARK: - Private API

    private func didUpdateCall(_ call: Call?, oldValue: Call?) {
        guard call?.cId != oldValue?.cId else { return }

        callParticipantsObservation?.cancel()
        callParticipantsObservation = nil
        maxAggregatedParticipantsCount = 0
        currentParticipantsCount = 0

        guard let call, call.cId == latestRingingCallCid else { return }

        Task { @MainActor in
            callParticipantsObservation = call
                .state
                .$participantsMap
                .map(\.count)
                .assign(to: \.currentParticipantsCount, onWeak: self)
        }
    }

    @MainActor
    private func checkTrigger(currentCount: Int, maxCount: Int) {
        guard let activeCall else { return }

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
