//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Defines timing delays for action processing in the store.
///
/// The `Delay` struct allows you to specify delays before and/or after
/// an action is processed. This is useful for:
/// - Debouncing rapid action dispatches
/// - Creating artificial delays for testing
/// - Smoothing UI transitions
/// - Rate limiting certain operations
///
/// ## Usage Examples
///
/// ```swift
/// // No delay (default)
/// store.dispatch(.someAction, delay: .none())
///
/// // Delay before processing
/// store.dispatch(.someAction, delay: .init(before: 0.5))
///
/// // Delay after processing
/// store.dispatch(.someAction, delay: .init(after: 0.3))
///
/// // Delay both before and after
/// store.dispatch(.someAction, delay: .init(before: 0.2, after: 0.1))
/// ```
///
/// ## Execution Flow
///
/// When delays are specified, the action processing follows this order:
/// 1. Wait for `before` delay (if > 0)
/// 2. Process middleware
/// 3. Process reducers
/// 4. Update state
/// 5. Wait for `after` delay (if > 0)
struct StoreDelay: Equatable {
    /// The delay in seconds to wait before processing the action.
    ///
    /// Default is 0 (no delay). The delay occurs before middleware and
    /// reducers are executed.
    var before: TimeInterval = 0

    /// The delay in seconds to wait after processing the action.
    ///
    /// Default is 0 (no delay). The delay occurs after the state has
    /// been updated but before the next action in the queue is processed.
    var after: TimeInterval = 0

    /// Creates a delay configuration with no delays.
    ///
    /// This is equivalent to `Delay(before: 0, after: 0)`.
    ///
    /// - Returns: A delay configuration with no delays.
    static func none() -> Self { .init() }

    /// Applies the before delay if one is configured.
    ///
    /// This method is called internally by the store executor before
    /// processing the action. If `before` is 0 or negative, this method
    /// returns immediately.
    func applyDelayBeforeIfRequired() async {
        guard before > 0 else { return }
        await wait(for: before)
    }

    /// Applies the after delay if one is configured.
    ///
    /// This method is called internally by the store executor after
    /// successfully processing the action. If `after` is 0 or negative,
    /// this method returns immediately.
    ///
    /// - Note: The after delay is not applied if the action processing
    ///   throws an error.
    func applyDelayAfterIfRequired() async {
        guard after > 0 else { return }
        await wait(for: after)
    }

    /// Waits for the specified number of seconds.
    ///
    /// Uses `Task.sleep` for the delay, which is cancellation-aware.
    /// If the task is cancelled, the delay ends immediately.
    ///
    /// - Parameter seconds: The number of seconds to wait.
    private func wait(for seconds: TimeInterval) async {
        try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * seconds))
    }
}
