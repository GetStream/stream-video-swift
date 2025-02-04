//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

/// A class implementing the `AudioSessionProtocol` that manages the WebRTC
/// audio session for the application, handling settings and route management.
final class StreamRTCAudioSession: AudioSessionProtocol {

    private struct State: ReflectiveStringConvertible {
        var category: AVAudioSession.Category
        var mode: AVAudioSession.Mode
        var options: AVAudioSession.CategoryOptions
        var overrideInputPort: AVAudioSession.Port?
        var overrideOutputPort: AVAudioSession.PortOverride = .none
    }

    private var state: State {
        didSet { log.debug("AudioSession state updated \(state).", subsystems: .audioSession) }
    }

    /// A queue for processing audio session operations asynchronously.
    private let processingQueue = SerialActorQueue()

    /// The shared instance of `RTCAudioSession` used for WebRTC audio
    /// configuration and management.
    private let source: RTCAudioSession

    /// A Boolean value indicating whether the audio session is currently active.
    var isActive: Bool { source.isActive }

    /// The current audio route description for the session.
    var currentRoute: AVAudioSessionRouteDescription { source.currentRoute }

    /// The audio category of the session, such as `.playAndRecord`.
    var category: String { source.category }

    /// A Boolean value indicating whether the audio session is using
    /// the device's speaker.
    var isUsingSpeakerOutput: Bool { currentRoute.isSpeaker }

    /// A Boolean value indicating whether the audio session is using
    /// an external output, like Bluetooth or headphones.
    var isUsingExternalOutput: Bool { currentRoute.isExternal }

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

    init() {
        let source = RTCAudioSession.sharedInstance()
        self.source = source
        state = .init(
            category: .init(rawValue: source.category),
            mode: .init(rawValue: source.mode),
            options: source.categoryOptions
        )
    }

    /// Adds a delegate to receive updates from the audio session.
    /// - Parameter delegate: A delegate conforming to `RTCAudioSessionDelegate`.
    func add(_ delegate: RTCAudioSessionDelegate) {
        source.add(delegate)
    }

    /// Sets the audio mode for the session, such as `.videoChat`.
    /// - Parameter mode: The audio mode to set.
    /// - Throws: An error if setting the mode fails.
    func setMode(_ mode: AVAudioSession.Mode) throws {
        try source.setMode(mode)
    }

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
    ) throws {
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

        state.category = category
        state.mode = mode
        state.options = categoryOptions
    }

    /// Activates or deactivates the audio session.
    /// - Parameter isActive: A Boolean indicating whether the session
    ///   should be active.
    /// - Throws: An error if activation or deactivation fails.
    func setActive(_ isActive: Bool) throws {
        try source.setActive(isActive)
    }

    /// Sets the audio configuration for the WebRTC session.
    /// - Parameter configuration: The configuration to apply.
    /// - Throws: An error if setting the configuration fails.
    func setConfiguration(_ configuration: RTCAudioSessionConfiguration) throws {
        try source.setConfiguration(configuration)
        state.category = .init(rawValue: configuration.category)
        state.mode = .init(rawValue: configuration.mode)
        state.options = configuration.categoryOptions
    }

    /// Overrides the audio output port, such as switching to speaker output.
    /// - Parameter port: The output port to use, such as `.speaker`.
    /// - Throws: An error if overriding the output port fails.
    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) throws {
        guard state.overrideOutputPort != port else {
            return
        }
        try source.overrideOutputAudioPort(port)
        state.overrideOutputPort = port
    }

    /// Performs an asynchronous update to the audio session configuration.
    /// - Parameters:
    ///   - functionName: The name of the calling function.
    ///   - file: The source file of the calling function.
    ///   - line: The line number of the calling function.
    ///   - block: A closure that performs an audio configuration update.
    func updateConfiguration(
        functionName: StaticString,
        file: StaticString,
        line: UInt,
        _ block: @escaping (any AudioSessionProtocol) throws -> Void
    ) async {
        try? await processingQueue.sync { [weak self] in
            guard let self else { return }
            source.lockForConfiguration()
            defer { source.unlockForConfiguration() }
            do {
                try block(self)
            } catch {
                log.error(
                    error,
                    subsystems: .audioSession,
                    functionName: functionName,
                    fileName: file,
                    lineNumber: line
                )
            }
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
}

/// A key for dependency injection of an `AudioSessionProtocol` instance
/// that represents the active call audio session.
struct StreamActiveCallAudioSessionKey: InjectionKey {
    static var currentValue: StreamAudioSessionAdapter?
}

extension InjectedValues {
    /// The active call's audio session. The value is being set on `StreamAudioSessionAdapter`
    /// `init` / `deinit`
    var activeCallAudioSession: StreamAudioSessionAdapter? {
        get {
            Self[StreamActiveCallAudioSessionKey.self]
        }
        set {
            Self[StreamActiveCallAudioSessionKey.self] = newValue
        }
    }
}
