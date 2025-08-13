//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class CallAudioRecordingStore: @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    var state: State { stateSubject.value }

    private let stateSubject: CurrentValueSubject<State, Never> = .init(.initial)
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private let actionLogger = ActionLogger()

    @Atomic private(set) var reducers: [CallAudioRecordingReducer] = [
        DefaultReducer()
    ]

    @Atomic private(set) var middleware: [CallAudioRecordingMiddleware] = []

    init() {
        middleware = [
            InterruptionMiddleware(self),
            AVAudioRecorderMiddleware(self),
            ActiveCallMiddleware(self),
            CategoryMiddleware(self),
            ApplicationStateMiddleware(self)
        ]
    }

    // MARK: - State Observation

    /// Publishes changes to the specified state property.
    ///
    /// Use this to observe changes for a specific audio state key path.
    func publisher<V: Equatable>(
        _ keyPath: KeyPath<State, V>
    ) -> AnyPublisher<V, Never> {
        stateSubject
            .map { $0[keyPath: keyPath] }
            .eraseToAnyPublisher()
    }

    func dispatch(
        _ action: CallAudioRecordingAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }

            do {
                try perform(
                    action,
                    file: file,
                    function: function,
                    line: line
                )
            } catch {
                log.error(
                    error,
                    subsystems: .audioRecording,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            }
        }
    }

    // MARK: - Private Helpers

    private func perform(
        _ action: CallAudioRecordingAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) throws {
        let state = stateSubject.value

        let middleware = middleware
        let reducers = reducers

        middleware.forEach {
            $0.apply(
                state: state,
                action: action,
                file: file,
                function: function,
                line: line
            )
        }

        do {
            let updatedState = try reducers
                .reduce(state) {
                    try $1.reduce(
                        state: $0,
                        action: action,
                        file: file,
                        function: function,
                        line: line
                    )
                }

            stateSubject.send(updatedState)

            actionLogger.didComplete(
                action: action,
                state: updatedState,
                file: file,
                function: function,
                line: line
            )
        } catch {
            actionLogger.didFail(
                action: action,
                error: error,
                file: file,
                function: function,
                line: line
            )
            throw error
        }
    }
}

extension CallAudioRecordingStore {

    final class ActionLogger {

        private var metersUpdated: [Float] = []
        private let metersUpdatedLimit: Int = 500

        func didComplete(
            action: CallAudioRecordingAction,
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
                    "Completed \(metersUpdatedLimit) meter actions with average:\(average)db.",
                    subsystems: .audioRecording,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            } else {
                log.debug(
                    "Completed action: \(action).",
                    subsystems: .audioRecording,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            }
        }

        func didFail(
            action: CallAudioRecordingAction,
            error: Error,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            log.error(
                "Failed action: \(action).",
                subsystems: .audioRecording,
                error: error,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
        }
    }
}
