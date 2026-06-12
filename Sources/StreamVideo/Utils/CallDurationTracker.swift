//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Tracks the elapsed duration of a call session.
///
/// The tracker observes backend session payloads and runs a 1-second timer
/// while a session is active. The timer anchors on the backend session start
/// or, when set, on a local start date. The local anchor is used when a join
/// interceptor delays call entry, so the visible duration starts only once
/// the user has actually joined.
///
/// - Important: The tracker does not guarantee delivery on any specific
///   thread. Subscribers that feed UI state should hop to the main queue.
final class CallDurationTracker: @unchecked Sendable {

    /// Publishes the elapsed duration of the active session in seconds.
    ///
    /// Emits `0` while no session is running and updates every second once
    /// the duration timer has been anchored.
    var durationPublisher: AnyPublisher<TimeInterval, Never> {
        durationSubject.eraseToAnyPublisher()
    }

    /// Publishes the backend-reported session start date.
    ///
    /// This always reflects the backend value, even when the duration is
    /// anchored to a local override.
    var startedAtPublisher: AnyPublisher<Date?, Never> {
        startedAtSubject.eraseToAnyPublisher()
    }

    /// When set, the duration is measured from this local date instead of
    /// the backend session start.
    ///
    /// The join flow sets this once a join interceptor has delayed call
    /// entry. It is cleared whenever the duration resets (e.g. the session
    /// ends).
    var startOverride: Date? {
        didSet {
            guard startOverride != oldValue else {
                return
            }
            configure(for: session)
        }
    }

    private let durationSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private let startedAtSubject = CurrentValueSubject<Date?, Never>(nil)
    private var session: CallSessionResponse?
    /// The date the running timer is currently anchored to. Used to avoid
    /// restarting the timer on repeated session updates.
    private var anchor: Date?
    private var timerCancellable: AnyCancellable?

    init() {}

    /// Updates the tracker with the latest backend session payload.
    func didUpdate(_ session: CallSessionResponse?) {
        self.session = session
        configure(for: session)
    }

    // MARK: - Private Helpers

    private func configure(for session: CallSessionResponse?) {
        if session?.endedAt != nil || session?.liveEndedAt != nil {
            reset()
            return
        }

        let sessionStartedAt = session?.startedAt ?? session?.liveStartedAt

        if let sessionStartedAt, sessionStartedAt != startedAtSubject.value {
            startedAtSubject.send(sessionStartedAt)
        }

        if let anchor = startOverride ?? sessionStartedAt {
            startTimer(from: anchor)
        } else if startedAtSubject.value == nil {
            reset()
        }
    }

    /// Starts the duration timer anchored to the provided date. Repeated
    /// calls with the same anchor keep the running timer untouched.
    private func startTimer(from anchor: Date) {
        guard anchor != self.anchor else {
            return
        }
        self.anchor = anchor

        timerCancellable?.cancel()
        timerCancellable = DefaultTimer
            .publish(every: 1.0)
            .map { _ in Date().timeIntervalSince(anchor) }
            .sink { [weak self] in self?.durationSubject.send($0) }

        durationSubject.send(Date().timeIntervalSince(anchor).rounded())
    }

    /// Stops the duration timer and clears every duration related anchor.
    private func reset() {
        timerCancellable?.cancel()
        timerCancellable = nil

        anchor = nil
        startOverride = nil
        durationSubject.send(0)
        startedAtSubject.send(nil)
    }
}
