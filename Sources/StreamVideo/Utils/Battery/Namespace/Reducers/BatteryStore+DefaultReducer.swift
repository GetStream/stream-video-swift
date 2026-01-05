//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

extension BatteryStore.Namespace {

    final class DefaultReducer: Reducer<BatteryStore.Namespace>, @unchecked Sendable {
        /// Processes an action to produce a new state.
        ///
        /// This method creates a copy of the current state, applies the
        /// action's changes, and returns the updated state.
        ///
        /// - Parameters:
        ///   - state: The current state before the action.
        ///   - action: The action to process.
        ///   - file: Source file where the action was dispatched.
        ///   - function: Function name where the action was dispatched.
        ///   - line: Line number where the action was dispatched.
        ///
        /// - Returns: A new state reflecting the action's changes.
        ///
        /// - Throws: This implementation doesn't throw, but the protocol
        ///   allows for error handling in complex reducers.
        override func reduce(
            state: State,
            action: Action,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) async throws -> State {
            var updatedState = state

            switch action {
            case let .setMonitoringEnabled(value):
                #if canImport(UIKit)
                await MainActor.run { UIDevice.current.isBatteryMonitoringEnabled = value }
                updatedState.isMonitoringEnabled = value
                #else
                break
                #endif

            case let .setLevel(value):
                if value >= 0 {
                    let percentage = Double(value) * 100
                    let rounded = percentage.rounded()
                    updatedState.level = Int(max(0, min(rounded, 100)))
                } else {
                    updatedState.level = 0
                }

            case let .setState(value):
                updatedState.state = value
            }

            return updatedState
        }
    }
}
