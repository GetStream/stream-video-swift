//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A logger for recording store operations and debugging state changes.
///
/// The store logger provides visibility into the action processing
/// pipeline, logging successful completions and failures. It can be
/// subclassed to customize logging behavior for specific stores.
///
/// ## Customization
///
/// Subclass this logger to:
/// - Filter or aggregate certain actions
/// - Add custom formatting
/// - Send metrics to analytics
/// - Implement performance monitoring
///
/// ## Example
///
/// ```swift
/// class CustomLogger: StoreLogger<MyNamespace> {
///     override func didComplete(
///         identifier: String,
///         action: Action,
///         state: State,
///         file: StaticString,
///         function: StaticString,
///         line: UInt
///     ) {
///         // Custom logging logic
///         if case .criticalAction = action {
///             sendAnalytics(action: action)
///         }
///         super.didComplete(...)
///     }
/// }
/// ```
class StoreLogger<Namespace: StoreNamespace> {

    /// The logging subsystem for categorizing log messages.
    ///
    /// This allows filtering logs by subsystem in the console or log
    /// aggregation tools.
    let logSubsystem: LogSubsystem

    /// Aggregated metrics recorded for dispatched actions.
    ///
    /// Statistics are enabled in DEBUG builds to help monitor action
    /// throughput.
    let statistics: StoreStatistics<Namespace> = .init()

    let logSkipped: Bool

    /// Initializes a new store logger.
    ///
    /// - Parameter logSubsystem: The subsystem for categorizing logs.
    ///   Defaults to `.other`.
    init(
        logSubsystem: LogSubsystem = .other,
        logSkipped: Bool = true
    ) {
        self.logSubsystem = logSubsystem
        self.logSkipped = logSkipped

        #if DEBUG
        statistics.enable(interval: 60) {
            [weak self] numberOfActions, interval in
            self?.report(numberOfActions, interval: interval)
        }
        #endif
    }

    /// Called when an action has been successfully processed.
    ///
    /// Override this method to customize logging for successful actions.
    /// The default implementation logs at debug level.
    ///
    /// - Parameters:
    ///   - identifier: The store's unique identifier.
    ///   - action: The action that was processed.
    ///   - state: The new state after processing.
    ///   - file: Source file where the action was dispatched.
    ///   - function: Function where the action was dispatched.
    ///   - line: Line number where the action was dispatched.
    func didComplete(
        identifier: String,
        action: Namespace.Action,
        state: Namespace.State,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        defer { statistics.record(action) }
        log.debug(
            "Store identifier:\(identifier) completed action:\(action) "
                + "state:\(state).",
            subsystems: logSubsystem,
            functionName: function,
            fileName: file,
            lineNumber: line
        )
    }

    /// Called when an action is skipped by the coordinator.
    ///
    /// Override to customize logging or metrics for redundant actions
    /// that do not require processing.
    ///
    /// - Parameters:
    ///   - identifier: The store's unique identifier.
    ///   - action: The action that was skipped.
    ///   - state: The snapshot used when making the decision.
    ///   - file: Source file where the action was dispatched.
    ///   - function: Function where the action was dispatched.
    ///   - line: Line number where the action was dispatched.
    func didSkip(
        identifier: String,
        action: Namespace.Action,
        state: Namespace.State,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        defer { statistics.record(action) }

        guard logSkipped else { return }

        log.debug(
            "Store identifier:\(identifier) skipped action:\(action).",
            subsystems: logSubsystem,
            functionName: function,
            fileName: file,
            lineNumber: line
        )
    }

    /// Called when an action fails during processing.
    ///
    /// Override this method to customize error logging. The default
    /// implementation logs at error level with the error details.
    ///
    /// - Parameters:
    ///   - identifier: The store's unique identifier.
    ///   - action: The action that failed.
    ///   - error: The error that occurred during processing.
    ///   - file: Source file where the action was dispatched.
    ///   - function: Function where the action was dispatched.
    ///   - line: Line number where the action was dispatched.
    func didFail(
        identifier: String,
        action: Namespace.Action,
        error: Error,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        defer { statistics.record(action) }
        log.error(
            "Store identifier:\(identifier) failed to apply action:\(action).",
            subsystems: logSubsystem,
            error: error,
            functionName: function,
            fileName: file,
            lineNumber: line
        )
    }

    /// Reports aggregated statistics for the store.
    ///
    /// This hook is invoked on a timer when statistics tracking is
    /// enabled. Override to forward metrics or customize formatting.
    ///
    /// - Parameters:
    ///   - numberOfActions: Count of actions recorded in the interval.
    ///   - interval: The time window for the reported statistics.
    func report(
        _ numberOfActions: Int,
        interval: TimeInterval
    ) {
        log.debug(
            "Store identifier:\(Namespace.identifier) performs "
                + "\(numberOfActions) per \(interval) seconds.",
            subsystems: logSubsystem
        )
    }
}
