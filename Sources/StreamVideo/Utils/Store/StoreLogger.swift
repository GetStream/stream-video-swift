//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

    let statistics: StoreStatistics<Namespace> = .init()

    /// Initializes a new store logger.
    ///
    /// - Parameter logSubsystem: The subsystem for categorizing logs.
    ///   Defaults to `.other`.
    init(logSubsystem: LogSubsystem = .other) {
        self.logSubsystem = logSubsystem

        #if DEBUG
        statistics.enable(interval: 60) { [weak self] in self?.report($0, interval: $1) }
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
            "Store identifier:\(identifier) completed action:\(action) state:\(state).",
            subsystems: logSubsystem,
            functionName: function,
            fileName: file,
            lineNumber: line
        )
    }

    func didSkip(
        identifier: String,
        action: Namespace.Action,
        state: Namespace.State,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        defer { statistics.record(action) }
        log.debug(
            "Store identifier:\(identifier) skipped action:\(action)).",
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

    func report(
        _ numberOfActions: Int,
        interval: TimeInterval
    ) {
        log.debug(
            "Store identifier:\(Namespace.identifier) performs \(numberOfActions) per \(interval) seconds.",
            subsystems: logSubsystem
        )
    }
}
