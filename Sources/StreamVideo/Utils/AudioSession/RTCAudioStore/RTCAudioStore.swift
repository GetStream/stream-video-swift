//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Stores and manages the audio session state for real-time communication calls.
///
/// `RTCAudioStore` coordinates actions, state updates, and reducers for audio
/// session control. It centralizes audio configuration, provides state
/// observation, and enables serial action processing to avoid concurrency
/// issues. Use this type to access and manage all call audio state in a
/// thread-safe, observable way.
final class RTCAudioStore: @unchecked Sendable {

    static let shared = RTCAudioStore()

    /// The current state of the audio session.
    var state: State { stateSubject.value }

    /// The underlying WebRTC audio session being managed.
    let session: AudioSessionProtocol

    private let stateSubject: CurrentValueSubject<State, Never>
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    @Atomic private(set) var middleware: [RTCAudioStoreMiddleware] = []
    @Atomic private(set) var reducers: [RTCAudioStoreReducer] = []

    init(
        session: AudioSessionProtocol = RTCAudioSession.sharedInstance(),
        underlyingQueue: dispatch_queue_t? = .global(qos: .userInteractive)
    ) {
        self.session = session
        
        stateSubject = .init(
            .init(
                isActive: session.isActive,
                isInterrupted: false,
                prefersNoInterruptionsFromSystemAlerts: session.prefersNoInterruptionsFromSystemAlerts,
                isAudioEnabled: session.isAudioEnabled,
                useManualAudio: session.useManualAudio,
                category: .init(rawValue: session.category),
                mode: .init(rawValue: session.mode),
                options: session.categoryOptions,
                overrideOutputAudioPort: .none,
                hasRecordingPermission: session.recordPermissionGranted,
                stereoPlayout: false,
                stereoRecording: false
            )
        )
        processingQueue.underlyingQueue = underlyingQueue

        add(RTCAudioSessionReducer(store: self))
        add(StereoRecordingMiddleware(self))

        dispatch(.audioSession(.setPrefersNoInterruptionsFromSystemAlerts(true)))
        dispatch(.audioSession(.useManualAudio(true)))
        dispatch(.audioSession(.isAudioEnabled(false)))
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
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Reducers

    /// Adds middleware to observe or intercept audio actions.
    func add<T: RTCAudioStoreMiddleware>(_ value: T) {
        guard middleware.first(where: { $0 === value }) == nil else {
            return
        }
        middleware.append(value)
    }

    /// Removes previously added middleware.
    func remove<T: RTCAudioStoreMiddleware>(_ value: T) {
        middleware = middleware.filter { $0 !== value }
    }

    // MARK: - Reducers

    /// Adds a reducer to handle audio session actions.
    func add<T: RTCAudioStoreReducer>(_ value: T) {
        guard reducers.first(where: { $0 === value }) == nil else {
            return
        }
        reducers.append(value)
    }

    /// Adds a reducer to handle audio session actions.
    func remove<T: RTCAudioStoreReducer>(_ value: T) {
        reducers = reducers.filter { $0 !== value }
    }

    // MARK: - Actions dispatch

    /// Dispatches an audio store action asynchronously and waits for completion.
    func dispatchAsync(
        _ actions: [RTCAudioStoreAction],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
            guard let self else {
                return
            }

            for action in actions {
                await applyDelayIfRequired(for: action)

                if case let .failable(nestedAction) = action {
                    do {
                        try perform(
                            nestedAction,
                            file: file,
                            function: function,
                            line: line
                        )
                    } catch {
                        log.warning(
                            "RTCAudioStore action:\(nestedAction) failed with error:\(error).",
                            functionName: function,
                            fileName: file,
                            lineNumber: line
                        )
                    }
                } else {
                    try perform(
                        action,
                        file: file,
                        function: function,
                        line: line
                    )
                }
            }
        }
    }

    /// Dispatches an audio store action asynchronously and waits for completion.
    func dispatchAsync(
        _ action: RTCAudioStoreAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await dispatchAsync(
            [action],
            file: file,
            function: function,
            line: line
        )
    }

    func dispatch(
        _ actions: [RTCAudioStoreAction],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }

            for action in actions {
                do {
                    await applyDelayIfRequired(for: action)

                    if case let .failable(nestedAction) = action {
                        do {
                            try perform(
                                nestedAction,
                                file: file,
                                function: function,
                                line: line
                            )
                        } catch {
                            log.warning(
                                "RTCAudioStore action:\(nestedAction) failed with error:\(error).",
                                functionName: function,
                                fileName: file,
                                lineNumber: line
                            )
                        }
                    } else {
                        try perform(
                            action,
                            file: file,
                            function: function,
                            line: line
                        )
                    }
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
    }

    /// Dispatches an audio store action for processing on the queue.
    func dispatch(
        _ action: RTCAudioStoreAction,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        dispatch([action], file: file, function: function, line: line)
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
                "Store identifier:RTCAudioStore completed action:\(action) state:\(updatedState).",
                subsystems: .audioSession,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
        } catch {
            log.error(
                "Store identifier:RTCAudioStore failed to apply action:\(action) state:\(state).",
                subsystems: .audioSession,
                error: error,
                functionName: function,
                fileName: file,
                lineNumber: line
            )
            throw error
        }
    }

    /// Delays are important for flows like interruptionEnd where we need to perform multiple operations
    /// at once while the same session may be accessed/modified from another part of the app (e.g. CallKit).
    private func applyDelayIfRequired(for action: RTCAudioStoreAction) async {
        guard
            case let .generic(.delay(interval)) = action
        else {
            return
        }

        try? await Task.sleep(nanoseconds: UInt64(1_000_000_000 * interval))
    }
}

extension RTCAudioStore: InjectionKey {
    nonisolated(unsafe) static var currentValue: RTCAudioStore = .shared
}

extension InjectedValues {
    var audioStore: RTCAudioStore {
        get { Self[RTCAudioStore.self] }
        set { Self[RTCAudioStore.self] = newValue }
    }
}
