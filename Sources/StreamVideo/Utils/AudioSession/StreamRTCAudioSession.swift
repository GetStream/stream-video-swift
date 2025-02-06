//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamWebRTC

/// A class implementing the `AudioSessionProtocol` that manages the WebRTC
/// audio session for the application, handling settings and route management.
final class StreamRTCAudioSession: @unchecked Sendable, ReflectiveStringConvertible {

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

        source
            .publisher(for: \.category)
            .sink { [weak self] in self?.state.category = .init(rawValue: $0) }
            .store(in: disposableBag)
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
        with categoryOptions: AVAudioSession.CategoryOptions,
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) async throws {
        try await performOperation { [weak self] in
            guard let self else {
                return
            }

            guard category != state.category
                || mode != state.mode
                || categoryOptions != state.options
            else {
                return
            }

            if category != state.category {
                if mode != state.mode {
                    try source.setCategory(
                        category,
                        mode: mode,
                        options: categoryOptions
                    )
                    try source.setActive(isActive)
                } else {
                    try source.setCategory(
                        category,
                        with: categoryOptions
                    )
                }
            } else {
                if mode != state.mode {
                    if categoryOptions != state.options {
                        try source.setCategory(
                            category,
                            mode: mode,
                            options: categoryOptions
                        )
                        try source.setActive(isActive)
                    } else {
                        try source.setMode(mode)
                    }
                } else if categoryOptions != state.options {
                    try source.setCategory(
                        category,
                        with: categoryOptions
                    )
                } else {
                    /* No-op */
                }
            }

            state = .init(
                category: category,
                mode: mode,
                options: categoryOptions,
                overrideOutputPort: state.overrideOutputPort
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

            guard state.overrideOutputPort != port else {
                return
            }

            try source.overrideOutputAudioPort(port)
            state.overrideOutputPort = port
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
}
