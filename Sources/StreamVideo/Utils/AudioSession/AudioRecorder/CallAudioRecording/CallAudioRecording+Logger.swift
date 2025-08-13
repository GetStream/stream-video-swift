//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallAudioRecording {

    final class CallAudioRecordingLogger: StoreLogger<CallAudioRecording> {
        private var metersUpdated: [Float] = []
        private let metersUpdatedLimit: Int = 500

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
