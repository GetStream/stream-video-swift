//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// A protocol defining an interface for managing an audio session.
/// This allows for dependency injection and easier testing.
protocol AudioSessionProtocol {

    /// A publisher that emits audio session events.
    var eventPublisher: AnyPublisher<AudioSessionEvent, Never> { get }

    /// A Boolean value indicating whether the audio session is active.
    var isActive: Bool { get }

    /// The current audio route description for the session.
    var currentRoute: AVAudioSessionRouteDescription { get }

    var category: AVAudioSession.Category { get }

    /// A Boolean value indicating whether manual audio routing is used.
    var useManualAudio: Bool { get set }

    /// A Boolean value indicating whether audio is enabled.
    var isAudioEnabled: Bool { get set }

    /// Configures the audio session category and options.
    /// - Parameters:
    ///   - category: The audio category (e.g., `.playAndRecord`).
    ///   - mode: The audio mode (e.g., `.videoChat`).
    ///   - categoryOptions: The options for the category (e.g., `.allowBluetooth`).
    /// - Throws: An error if setting the category fails.
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) async throws

    /// Activates or deactivates the audio session.
    /// - Parameter isActive: Whether to activate the session.
    /// - Throws: An error if activation fails.
    func setActive(_ isActive: Bool) async throws

    /// Overrides the audio output port (e.g., to speaker).
    /// - Parameter port: The output port override.
    /// - Throws: An error if overriding fails.
    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) async throws

    /// Requests permission to record audio from the user.
    /// - Returns: `true` if permission was granted, otherwise `false`.
    func requestRecordPermission() async -> Bool
}

/// A class implementing the `AudioSessionProtocol` that manages the WebRTC
/// audio session for the application, handling settings and route management.
final class StreamRTCAudioSession: AudioSessionProtocol, @unchecked Sendable, ReflectiveStringConvertible {

    struct State: ReflectiveStringConvertible {
        var category: AVAudioSession.Category
        var mode: AVAudioSession.Mode
        var options: AVAudioSession.CategoryOptions
        var overrideOutputPort: AVAudioSession.PortOverride = .none
    }

    @Published private(set) var state: State

    /// A queue for processing audio session operations asynchronously.
    private let processingQueue = SerialActorQueue()

    /// The shared instance of `RTCAudioSession` used for WebRTC audio
    /// configuration and management.
    private let source: RTCAudioSession
    private let sourceDelegate: RTCAudioSessionDelegatePublisher = .init()
    private let disposableBag = DisposableBag()

    var eventPublisher: AnyPublisher<AudioSessionEvent, Never> {
        sourceDelegate.publisher
    }

    /// A Boolean value indicating whether the audio session is currently active.
    var isActive: Bool { source.isActive }

    /// The current audio route description for the session.
    var currentRoute: AVAudioSessionRouteDescription { source.currentRoute }

    var category: AVAudioSession.Category { state.category }

    /// A Boolean value indicating whether the audio session uses manual
    /// audio routing.
    var useManualAudio: Bool {
        set { source.useManualAudio = newValue }
        get { source.useManualAudio }
    }

    /// A Boolean value indicating whether audio is enabled for the session.
    var isAudioEnabled: Bool {
        set { source.isAudioEnabled = newValue }
        get { source.isAudioEnabled }
    }

    // MARK: - Lifecycle

    init() {
        let source = RTCAudioSession.sharedInstance()
        self.source = source
        state = .init(
            category: .init(rawValue: source.category),
            mode: .init(rawValue: source.mode),
            options: source.categoryOptions
        )
        source.add(sourceDelegate)
    }

    // MARK: - Configuration

    /// Configures the audio category and category options for the session.
    /// - Parameters:
    ///   - category: The audio category, such as `.playAndRecord`.
    ///   - categoryOptions: Options for the category, including
    ///     `.allowBluetooth` and `.defaultToSpeaker`.
    /// - Throws: An error if setting the category fails.
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) async throws {
        try await performOperation { [weak self] in
            guard let self else { return }

            let state = self.state
            let needsCategoryUpdate = category != state.category
            let needsModeUpdate = mode != state.mode
            let needsOptionsUpdate = categoryOptions != state.options

            guard needsCategoryUpdate || needsModeUpdate || needsOptionsUpdate else {
                return
            }

            if needsCategoryUpdate || needsOptionsUpdate {
                if needsModeUpdate {
                    try source.setCategory(
                        category,
                        mode: mode,
                        options: categoryOptions
                    )
                } else {
                    try source.setCategory(category, with: categoryOptions)
                }
            } else if needsModeUpdate {
                try source.setMode(mode)
            }

            self.state = .init(
                category: category,
                mode: mode,
                options: categoryOptions,
                overrideOutputPort: state.overrideOutputPort
            )

            updateWebRTCConfiguration(with: self.state)

            log.debug("AudioSession updated with state \(self.state)", subsystems: .audioSession)
        }
    }

    /// Activates or deactivates the audio session.
    /// - Parameter isActive: A Boolean indicating whether the session
    ///   should be active.
    /// - Throws: An error if activation or deactivation fails.
    func setActive(
        _ isActive: Bool
    ) async throws {
        try await performOperation { [weak self] in
            guard let self else {
                return
            }

            try source.setActive(isActive)
        }
    }

    /// Overrides the audio output port, such as switching to speaker output.
    /// - Parameter port: The output port to use, such as `.speaker`.
    /// - Throws: An error if overriding the output port fails.
    func overrideOutputAudioPort(
        _ port: AVAudioSession.PortOverride
    ) async throws {
        try await performOperation { [weak self] in
            guard let self else {
                return
            }

            guard
                state.category == .playAndRecord,
                state.overrideOutputPort != port
            else {
                return
            }

            try source.overrideOutputAudioPort(port)
            state.overrideOutputPort = port
            log.debug("AudioSession updated with state \(self.state)", subsystems: .audioSession)
        }
    }

    /// Requests permission to record audio from the user.
    /// - Returns: A Boolean indicating whether permission was granted.
    func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { result in
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Private Helpers

    private func performOperation(
        _ operation: @Sendable @escaping () async throws -> Void
    ) async throws {
        try await processingQueue.sync { [weak self] in
            guard let self else { return }
            source.lockForConfiguration()
            defer { source.unlockForConfiguration() }
            try await operation()
        }
    }

    /// Updates the WebRTC audio session configuration.
    ///
    /// - Parameter state: The current state of the audio session.
    ///
    /// - Note: This is required to ensure that the WebRTC audio session
    /// is configured correctly when the AVAudioSession is updated in
    /// order to avoid unexpected changes to the category.
    private func updateWebRTCConfiguration(with state: State) {
        let webRTCConfiguration = RTCAudioSessionConfiguration.webRTC()
        webRTCConfiguration.category = state.category.rawValue
        webRTCConfiguration.mode = state.mode.rawValue
        webRTCConfiguration.categoryOptions = state.options
        RTCAudioSessionConfiguration.setWebRTC(webRTCConfiguration)
    }
}
