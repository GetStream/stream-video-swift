//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class RTCAudioStore: @unchecked Sendable {

    enum Action { case delay(seconds: TimeInterval) }

    var state: State { stateSubject.value }
    var publisher: AnyPublisher<State, Never> { stateSubject.eraseToAnyPublisher() }

    let session: RTCAudioSession

    private let stateSubject: CurrentValueSubject<State, Never>
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    @Atomic private var middleware: [RTCAudioStoreMiddleware] = []
    @Atomic private var reducers: [RTCAudioStoreReducer] = []

    private init(
        session: RTCAudioSession = .sharedInstance(),
        underlyingQueue: dispatch_queue_t? = .global(qos: .userInteractive)
    ) {
        self.session = session
        let prefersNoInterruptionsFromSystemAlerts = {
            if #available(iOS 14.5, *) {
                return session.session.prefersNoInterruptionsFromSystemAlerts
            } else {
                return false
            }
        }()
        stateSubject = .init(
            .init(
                isActive: session.isActive,
                isInterrupted: false,
                prefersNoInterruptionsFromSystemAlerts: prefersNoInterruptionsFromSystemAlerts,
                isAudioEnabled: session.isAudioEnabled,
                useManualAudio: session.useManualAudio,
                category: .init(rawValue: session.category),
                mode: .init(rawValue: session.mode),
                options: session.categoryOptions,
                overrideOutputAudioPort: .none,
                hasRecordingPermission: session.session.recordPermission == .granted
            )
        )
        processingQueue.underlyingQueue = underlyingQueue

        add(RTCAudioSessionReducer())

        dispatch(.rtc(.setPrefersNoInterruptionsFromSystemAlerts(true)))
        dispatch(.rtc(.useManualAudio(true)))
        dispatch(.rtc(.isAudioEnabled(false)))
    }

    // MARK: - State Observation

    func publisher<V: Equatable>(
        _ keyPath: KeyPath<State, V>
    ) -> AnyPublisher<V, Never> {
        stateSubject
            .map { $0[keyPath: keyPath] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Reducers

    func add(_ value: RTCAudioStoreMiddleware) {
        middleware.append(value)
    }

    func add(_ value: RTCAudioStoreReducer) {
        reducers.append(value)
    }

    // MARK: - Actions dispatch

    func dispatchAsync(
        _ action: RTCAudioStoreAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else {
                return
            }

            if case let .store(.delay(interval)) = action {
                try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * interval))
            }

            try perform(
                action,
                file: file,
                function: function,
                line: line
            )
        }
    }

    func dispatch(
        _ action: RTCAudioStoreAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }

            do {
                if case let .store(.delay(interval)) = action {
                    try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * interval))
                }

                try perform(
                    action,
                    file: file,
                    function: function,
                    line: line
                )
            } catch {
                log.error(
                    error,
                    subsystems: .audioSession,
                    functionName: function,
                    fileName: file,
                    lineNumber: line
                )
            }
        }
    }

    // MARK: - Helpers

    func requestRecordPermission() async -> Bool {
        guard
            !state.hasRecordingPermission
        else {
            return true
        }

        let result = await session.session.requestRecordPermission()
        dispatch(.rtc(.setHasRecordingPermission(result)))
        return result
    }

    // MARK: - Private Helpers

    private func perform(
        _ action: RTCAudioStoreAction,
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

            log.debug(
                "Completed action: \(action).",
                subsystems: .audioSession,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
        } catch {
            log.error(
                "Failed action: \(action).",
                subsystems: .audioSession,
                error: error,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            throw error
        }
    }
}

extension RTCAudioStore: InjectionKey {
    nonisolated(unsafe) static var currentValue: RTCAudioStore = .init()
}

extension InjectedValues {
    var audioStore: RTCAudioStore {
        get { Self[RTCAudioStore.self] }
        set { Self[RTCAudioStore.self] = newValue }
    }
}
