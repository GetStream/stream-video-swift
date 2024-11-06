//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

/// A protocol defining the interface for managing an audio session,
/// with properties and methods to control audio settings, activation,
/// and routing configurations.
public protocol AudioSessionProtocol: AnyObject {

    /// A Boolean value indicating whether the audio session is active.
    var isActive: Bool { get }

    /// The current route description for the audio session.
    var currentRoute: AVAudioSessionRouteDescription { get }

    /// The audio category of the session.
    var category: String { get }

    /// A Boolean value indicating whether the audio session uses speaker output.
    var isUsingSpeakerOutput: Bool { get }

    /// A Boolean value indicating whether the audio session uses an external
    /// audio output, such as headphones or Bluetooth.
    var isUsingExternalOutput: Bool { get }

    /// A Boolean value indicating whether the session uses manual audio routing.
    var useManualAudio: Bool { get set }

    /// A Boolean value indicating whether audio is enabled for the session.
    var isAudioEnabled: Bool { get set }

    /// Adds a delegate to receive updates about audio session events.
    /// - Parameter delegate: The delegate conforming to `RTCAudioSessionDelegate`.
    func add(_ delegate: RTCAudioSessionDelegate)

    /// Sets the audio mode of the session.
    /// - Parameter mode: The audio mode to set, such as `.videoChat` or `.voiceChat`.
    /// - Throws: An error if setting the mode fails, usually because the configuration hasn't been locked.
    /// Prefer wrapping this method using `updateConfiguration`.
    func setMode(_ mode: String) throws

    /// Configures the audio category and options for the session.
    /// - Parameters:
    ///   - category: The audio category to set, like `.playAndRecord`.
    ///   - categoryOptions: Options for the audio category, such as
    ///     `.allowBluetooth` or `.defaultToSpeaker`.
    /// - Throws: An error if setting the mode fails, usually because the configuration hasn't been locked.
    /// Prefer wrapping this method using `updateConfiguration`.
    func setCategory(
        _ category: String,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) throws

    /// Activates or deactivates the audio session.
    /// - Parameter isActive: A Boolean indicating whether the session
    ///   should be activated.
    /// - Throws: An error if setting the mode fails, usually because the configuration hasn't been locked.
    /// Prefer wrapping this method using `updateConfiguration`.
    func setActive(_ isActive: Bool) throws

    /// Sets the session configuration for WebRTC audio settings.
    /// - Parameter configuration: The configuration to apply to the session.
    /// - Throws: An error if setting the mode fails, usually because the configuration hasn't been locked.
    /// Prefer wrapping this method using `updateConfiguration`.
    func setConfiguration(_ configuration: RTCAudioSessionConfiguration) throws

    /// Overrides the current output audio port for the session.
    /// - Parameter port: The port to use, such as `.speaker` or `.none`.
    /// - Throws: An error if setting the mode fails, usually because the configuration hasn't been locked.
    /// Prefer wrapping this method using `updateConfiguration`.
    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) throws

    /// Updates the audio session configuration by performing an asynchronous
    /// operation.
    /// - Parameters:
    ///   - functionName: The name of the calling function.
    ///   - file: The source file of the calling function.
    ///   - line: The line number of the calling function.
    ///   - block: The closure to execute, providing the audio session for
    ///     configuration updates.
    func updateConfiguration(
        functionName: StaticString,
        file: StaticString,
        line: UInt,
        _ block: @escaping (AudioSessionProtocol) throws -> Void
    )

    /// Requests permission to record audio from the user.
    /// - Returns: A Boolean indicating whether permission was granted.
    func requestRecordPermission() async -> Bool
}

extension AVAudioSession {
    /// Asynchronously requests permission to record audio.
    /// - Returns: A Boolean indicating whether permission was granted.
    private func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            self.requestRecordPermission { result in
                continuation.resume(returning: result)
            }
        }
    }
}
