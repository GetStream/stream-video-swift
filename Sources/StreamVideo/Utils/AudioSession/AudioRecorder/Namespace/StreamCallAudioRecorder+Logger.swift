//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamCallAudioRecorder.Namespace {

    /// A specialized logger for the call audio recording store that
    /// aggregates meter updates.
    ///
    /// This logger batches meter level updates to reduce log noise, only
    /// logging the average meter level after collecting a specified number
    /// of samples.
    final class StreamCallAudioRecorderLogger: StoreLogger<StreamCallAudioRecorder.Namespace> {
        /// Buffer to store meter values for averaging.
        private var metersUpdated: [Float] = []
        
        /// The number of meter samples to collect before logging the average.
        ///
        /// Once this limit is reached, the average is calculated and logged,
        /// and the buffer is reset.
        private let metersUpdatedLimit: Int = 500

        /// Handles completion of store actions with special processing for
        /// meter updates.
        ///
        /// For meter update actions, this method aggregates values and only
        /// logs when the buffer limit is reached. For other actions, it
        /// delegates to the parent implementation.
        ///
        /// - Parameters:
        ///   - identifier: The store identifier.
        ///   - action: The action that was completed.
        ///   - state: The resulting state after the action.
        ///   - file: The source file where the action was dispatched.
        ///   - function: The function where the action was dispatched.
        ///   - line: The line number where the action was dispatched.
        override func didComplete(
            identifier: String,
            action: Action,
            state: State,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            if case let .setMeter(value) = action {
                metersUpdated.append(value)
                guard
                    metersUpdated.endIndex == metersUpdatedLimit
                else {
                    return
                }

                let sum = metersUpdated.reduce(0, +)
                let average = sum / Float(metersUpdatedLimit)
                metersUpdated = []

                log.debug(
                    "Store identifier:\(identifier) completed action:\(action) state:\(state). Average:\(average)db",
                    subsystems: logSubsystem,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            } else {
                super.didComplete(
                    identifier: identifier,
                    action: action,
                    state: state,
                    file: file,
                    function: function,
                    line: line
                )
            }
        }
    }
}
