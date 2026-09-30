//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Polls the ring state of a ring the current user started.
///
/// Flow coverage:
/// - Caller: polls the outgoing ring when ring events stop arriving.
/// - Callee: does not poll incoming rings. Reconnect recovery covers them.
///
/// A lost ring outcome may not trigger a reconnect before the ring ends.
/// After a quiet period, this policy reads the lightweight ring-state API
/// until the backend's ring timeout. It requires a known session and can
/// be disabled through `VideoConfig`.
///
/// Unlike reconnect recovery, polling does not need a connection event.
/// The result is merged into `call.state.session`, where the SwiftUI
/// ringing flow handles it the same way as a WebSocket event.
///
/// `@unchecked Sendable`: the mutable state is only touched on the main
/// actor.
final class PollingRingingRecoveryPolicy: RingingRecoveryPolicy, @unchecked Sendable {

    var actionPublisher: AnyPublisher<RingingRecoveryAction, Never> {
        actionSubject.eraseToAnyPublisher()
    }

    /// Weak because `StreamVideo` owns the adapter that owns this policy.
    private weak var streamVideo: StreamVideo?
    /// How long a ring must stay quiet before the first poll.
    private let startAfter: TimeInterval
    /// The time between polls.
    private let interval: TimeInterval
    private let actionSubject = PassthroughSubject<RingingRecoveryAction, Never>()
    private var ringingCallCancellable: AnyCancellable?
    /// The polling of the current ring. Accessed only on the main actor.
    private var pollingCancellable: AnyCancellable?
    /// Invalidates queued work even when the same call starts ringing again.
    /// Accessed only on the main actor.
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
            // The call state we read below is main actor isolated.
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ringingCall in
                guard let self else { return }
                MainActor.assumeIsolated {
                    self.didUpdateRingingCall(ringingCall)
                }
            }
    }

    // MARK: - Private Helpers

    /// Starts polling for the new ringing call, if the current user is its
    /// caller.
    @MainActor
    private func didUpdateRingingCall(_ ringingCall: Call?) {
        // Only one call rings at a time, so any change ends the old polling.
        pollingId = nil
        pollingCancellable = nil

        // Callees are out of scope: they act on the ring themselves.
        guard
            let streamVideo,
            let call = ringingCall,
            call.state.createdBy?.id == streamVideo.user.id
        else {
            return
        }

        // Captured now: ending the call clears the session, and a later
        // ring gets a new one. Every poll must read this ring's session.
        guard let callSessionId = call.state.session?.id else {
            log.warning("Ringing call cid:\(call.cId) has no session to poll.")
            return
        }

        // Same fallback as JS: 0 turns a setting off, and a ring without
        // settings still gets a bounded window.
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

    /// Emits on the main queue after the quiet period, then every interval,
    /// until the ring times out.
    ///
    /// Nonisolated on purpose: the timers call these closures off the main
    /// actor.
    private func polls(
        of call: Call,
        until ringTimeout: TimeInterval
    ) -> AnyPublisher<Void, Never> {
        call
            .eventPublisher
            // Any ring outcome proves the socket still delivers events.
            .filter(\.isRingOutcome)
            .map { _ in () }
            // Starts the first quiet period as soon as the ring starts.
            .prepend(())
            .map { [startAfter, interval] in
                DefaultTimer
                    .publish(every: interval)
                    .map { _ in () }
                    // Poll right away once the quiet period ends.
                    .prepend(())
                    // Shifts the whole series, so the first poll lands at
                    // startAfter and the next ones every interval after it.
                    .delay(
                        for: .seconds(startAfter),
                        scheduler: DispatchQueue.main
                    )
            }
            // Each ring event cancels the previous timer, with any poll it
            // had pending, and starts the quiet period again. The event
            // restarts the wait instead of ending polling: it shows the
            // socket works, but in a group ring one rejection does not
            // settle the ring.
            .switchToLatest()
            // Stops at the backend's ring timeout. Its first tick is enough.
            .prefix(untilOutputFrom: DefaultTimer.publish(every: ringTimeout))
            .eraseToAnyPublisher()
    }

    /// Builds the poll that runs on the adapter's serial queue.
    ///
    /// Only 400 and 404 stop polling. Other errors, such as a timeout, are
    /// likely transient, so the next tick tries again.
    private func makeAction(
        for call: Call,
        callSessionId: String,
        pollingId: UUID,
        deadline: Date
    ) -> RingingRecoveryAction {
        { @MainActor [weak self, weak call] in
            try Task.checkCancellation()
            // Cancelling a timer cannot remove actions already in the queue.
            // Recheck the run and deadline when each action actually starts.
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
                // The session is gone or belongs to another call.
                stopPolling(call, pollingId: pollingId)
                // Rethrown so the adapter logs it.
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
    /// A missing session (400) or one that does not belong to the call (404)
    /// will never resolve, so polling it again is pointless.
    fileprivate var isTerminalForRingState: Bool {
        statusCode == 400 || statusCode == 404
    }
}
