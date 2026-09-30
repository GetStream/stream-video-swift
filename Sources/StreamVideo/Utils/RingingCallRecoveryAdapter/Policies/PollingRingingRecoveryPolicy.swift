//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Recovers ring outcomes lost without a WebSocket reconnect.
/// - Caller: polls a known session until the backend ring timeout.
/// - Callee: does not poll; reconnect recovery refreshes incoming rings.
///
/// Mutable state is main-actor confined (`@unchecked Sendable`).
final class PollingRingingRecoveryPolicy: RingingRecoveryPolicy, @unchecked Sendable {

    var actionPublisher: AnyPublisher<RingingRecoveryAction, Never> {
        actionSubject.eraseToAnyPublisher()
    }

    private weak var streamVideo: StreamVideo?
    private let startAfter: TimeInterval
    private let interval: TimeInterval
    private let actionSubject = PassthroughSubject<RingingRecoveryAction, Never>()
    private var ringingCallCancellable: AnyCancellable?
    private var pollingCancellable: AnyCancellable?
    /// Invalidates queued work when a new ring starts on the same Call.
    private var pollingId: UUID?

    init(
        _ streamVideo: StreamVideo,
        options: RingStatePollingOptions
    ) {
        self.streamVideo = streamVideo
        startAfter = options.startAfter
        interval = options.interval

        ringingCallCancellable = streamVideo
            .state
            .$ringingCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ringingCall in
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.didUpdateRingingCall(ringingCall)
                }
            }
    }

    // MARK: - Private Helpers

    @MainActor
    private func didUpdateRingingCall(_ ringingCall: Call?) {
        pollingId = nil
        pollingCancellable = nil

        guard
            let streamVideo,
            let call = ringingCall,
            call.state.createdBy?.id == streamVideo.user.id
        else {
            return
        }

        guard let callSessionId = call.state.session?.id else {
            log.warning("Ringing call cid:\(call.cId) has no session to poll.")
            return
        }

        // Match JS timeout precedence, ignoring disabled (zero) settings.
        let ring = call.state.settings?.ring
        let ringTimeoutMs = [ring?.autoCancelTimeoutMs, ring?.missedCallTimeoutMs]
            .compactMap { $0 }
            .first { $0 > 0 } ?? 30000
        let ringTimeout = TimeInterval(ringTimeoutMs) / 1000
        let pollingId = UUID()
        self.pollingId = pollingId
        let action = makeAction(
            for: call,
            callSessionId: callSessionId,
            pollingId: pollingId,
            deadline: Date().addingTimeInterval(ringTimeout)
        )

        pollingCancellable = polls(of: call, until: ringTimeout)
            .sink { [weak self] in self?.actionSubject.send(action) }

        log.debug("Ring state polling armed for cid:\(call.cId).")
    }

    private func polls(
        of call: Call,
        until ringTimeout: TimeInterval
    ) -> AnyPublisher<Void, Never> {
        call
            .eventPublisher
            .filter(\.isRingOutcome)
            .map { _ in () }
            .prepend(())
            .map { [startAfter, interval] in
                DefaultTimer
                    .publish(every: interval)
                    .map { _ in () }
                    .prepend(())
                    .delay(
                        for: .seconds(startAfter),
                        scheduler: DispatchQueue.main
                    )
            }
            // Restart the quiet period; one rejection may not end a group ring.
            .switchToLatest()
            .prefix(untilOutputFrom: DefaultTimer.publish(every: ringTimeout))
            .eraseToAnyPublisher()
    }

    private func makeAction(
        for call: Call,
        callSessionId: String,
        pollingId: UUID,
        deadline: Date
    ) -> RingingRecoveryAction {
        { @MainActor [weak self, weak call] in
            try Task.checkCancellation()
            // Cancelled timers can leave stale fetches queued.
            guard
                let self,
                let call,
                self.pollingId == pollingId,
                streamVideo?.state.ringingCall === call,
                call.state.session?.id == callSessionId,
                Date() < deadline
            else {
                return
            }

            do {
                try await call.updateRingState(callSessionId: callSessionId)
            } catch let error as APIError where error.isTerminalForRingState {
                stopPolling(call, pollingId: pollingId)
                throw error
            }
        }
    }

    @MainActor
    private func stopPolling(_ call: Call, pollingId: UUID) {
        // A late failure must not cancel a replacement run on the same call.
        guard self.pollingId == pollingId else { return }
        self.pollingId = nil
        pollingCancellable = nil
        log.debug("Ring state polling stopped for cid:\(call.cId).")
    }
}

extension VideoEvent {
    /// Events that settle all or part of a ring.
    fileprivate var isRingOutcome: Bool {
        switch self {
        case .typeCallAcceptedEvent, .typeCallRejectedEvent, .typeCallMissedEvent:
            return true
        default:
            return false
        }
    }
}

extension APIError {
    /// Errors that cannot recover for this ring session.
    fileprivate var isTerminalForRingState: Bool {
        statusCode == 400 || statusCode == 404
    }
}
