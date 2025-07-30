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

    var mode: AVAudioSession.Mode { get }

    var overrideOutputPort: AVAudioSession.PortOverride { get }

    /// A Boolean value indicating whether manual audio routing is used.
    var useManualAudio: Bool { get set }

    /// A Boolean value indicating whether audio is enabled.
    var isAudioEnabled: Bool { get set }

    var hasRecordPermission: Bool { get }

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

    func didActivate(_ audioSession: AVAudioSessionProtocol)

    func didDeactivate(_ audioSession: AVAudioSessionProtocol)
}

/// A class implementing the `AudioSessionProtocol` that manages the WebRTC
/// audio session for the application, handling settings and route management.
final class StreamRTCAudioSession: AudioSessionProtocol, @unchecked Sendable, ReflectiveStringConvertible {

    struct State: ReflectiveStringConvertible, Equatable {
        var category: AVAudioSession.Category
        var mode: AVAudioSession.Mode
        var options: AVAudioSession.CategoryOptions
        var overrideOutputPort: AVAudioSession.PortOverride = .none
    }

    @Published private(set) var state: State

    /// A queue for processing audio session operations asynchronously.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

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

    var mode: AVAudioSession.Mode { state.mode }

    var overrideOutputPort: AVAudioSession.PortOverride { state.overrideOutputPort }

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

    var hasRecordPermission: Bool { source.session.recordPermission == .granted }

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

            let currentState = self.state
            let updatedState = State(
                category: category,
                mode: mode,
                options: categoryOptions,
                overrideOutputPort: state.overrideOutputPort
            )

            do {
                updateWebRTCConfiguration(with: updatedState)
                try source.setConfiguration(.webRTC())
                self.state = updatedState
            } catch {
                updateWebRTCConfiguration(with: currentState)
                log.error(
                    """
                    Failed to setCategory:\(category) mode:\(mode) options:\(category).
                    Current values category:\(state.category) mode:\(state.mode) options:\(state.options)
                    """,
                    subsystems: .audioSession
                )
                throw error
            }

            log.debug(
                "AudioSession updated with state \(self.state)",
                subsystems: .audioSession
            )
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
            guard let self, source.isActive != isActive else {
                return
            }

            try source.setActive(isActive)
            log.debug("AudioSession updated isActive:\(isActive).", subsystems: .audioSession)
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

    func didActivate(_ audioSession: AVAudioSessionProtocol) {
        guard
            let avAudioSession = audioSession as? AVAudioSession
        else {
            return
        }

        source.audioSessionDidActivate(avAudioSession)
    }

    func didDeactivate(_ audioSession: AVAudioSessionProtocol) {
        guard
            let avAudioSession = audioSession as? AVAudioSession
        else {
            return
        }

        source.audioSessionDidDeactivate(avAudioSession)
    }

    // MARK: - Private Helpers

    private func performOperation(
        _ operation: @Sendable @escaping () async throws -> Void
    ) async throws {
        try await processingQueue.addSynchronousTaskOperation { [weak self] in
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

extension AVAudioSession.PortOverride {
    var stringValue: String {
        switch self {
        case .none:
            return "none"
        case .speaker:
            return "speaker"
        @unknown default:
            return "unknown"
        }
    }
}
