//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A repeating timer implementation using `DispatchSourceTimer`, conforming to
/// `RepeatingTimerControl`. It safely supports resuming and suspending while
/// operating on a background queue.
///
/// This timer operates off the main thread using a custom dispatch queue.
final class RepeatingTimer: RepeatingTimerControl, @unchecked Sendable {
    /// Represents the internal running state of the timer.
    private enum State {
        case suspended
        case resumed
    }

    /// The internal queue on which the timer state transitions and control
    /// operations are serialized.
    private let queue = DispatchQueue(label: "io.getstream.repeating-timer")

    /// Tracks whether the timer is currently suspended or running.
    private var state: State = .suspended

    /// The underlying GCD timer source.
    private let timer: DispatchSourceTimer

    /// Indicates whether the timer is currently active and running.
    var isRunning: Bool { state == .resumed }

    /// Initializes a new repeating timer that fires at the given interval on the
    /// specified queue.
    ///
    /// - Parameters:
    ///   - timeInterval: The interval at which the timer fires repeatedly.
    ///   - queue: The dispatch queue on which the timer's `onFire` handler will
    ///     be invoked. This queue can be a background queue.
    ///   - onFire: The callback invoked each time the timer fires.
    init(
        timeInterval: TimeInterval,
        queue: DispatchQueue,
        onFire: @escaping () -> Void
    ) {
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now() + .seconds(Int(timeInterval)),
            repeating: timeInterval,
            leeway: .seconds(1)
        )
        timer.setEventHandler(handler: onFire)
    }

    /// Cancels the timer and performs cleanup.
    ///
    /// If the timer is still suspended, it must first be resumed before
    /// cancelling to avoid a crash. This is a known behavior of GCD timers.
    deinit {
        timer.setEventHandler {}
        timer.cancel()
        // If the timer is suspended, calling cancel without resuming
        // triggers a crash. This is documented here:
        // https://forums.developer.apple.com/thread/15902
        if state == .suspended {
            timer.resume()
        }
    }

    /// Resumes the timer if it was previously suspended.
    ///
    /// This method is thread-safe and dispatched to an internal serial queue.
    func resume() {
        queue.async {
            if self.state == .resumed {
                return
            }

            self.state = .resumed
            self.timer.resume()
        }
    }

    /// Suspends the timer if it is currently running.
    ///
    /// This method is thread-safe and dispatched to an internal serial queue.
    func suspend() {
        queue.async {
            if self.state == .suspended {
                return
            }

            self.state = .suspended
            self.timer.suspend()
        }
    }

    func cancel() {
        suspend()
    }
}
