//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A protocol for controlling a repeating timer, allowing inspection and
/// management of its running state.
protocol RepeatingTimerControl: TimerControl {
    /// Resumes the timer if it was previously suspended.
    ///
    /// If the timer is already running, this call has no effect.
    func resume()

    /// Suspends the timer if it is currently running.
    ///
    /// If the timer is already suspended, this call has no effect.
    func suspend()

    /// A Boolean value indicating whether the timer is currently active and
    /// executing on schedule.
    var isRunning: Bool { get }
}
