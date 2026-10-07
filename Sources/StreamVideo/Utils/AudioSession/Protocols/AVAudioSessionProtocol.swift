//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

protocol AVAudioSessionProtocol {

    /// The session category used for audio routing.
    var category: AVAudioSession.Category { get }
    /// The mode used to configure audio processing.
    var mode: AVAudioSession.Mode { get }
    /// The options applied to the session category.
    var categoryOptions: AVAudioSession.CategoryOptions { get }
    /// The policy used to share audio routes.
    var routeSharingPolicy: AVAudioSession.RouteSharingPolicy { get }
    /// The audio modes supported by the session.
    var availableModes: [AVAudioSession.Mode] { get }
    /// The input selected for the next route change.
    var preferredInput: AVAudioSessionPortDescription? { get }
    /// The maximum number of output channels supported by the route.
    var maximumOutputNumberOfChannels: Int { get }
    /// The number of channels in the current output route.
    var outputNumberOfChannels: Int { get }
    /// The requested number of output channels.
    var preferredOutputNumberOfChannels: Int { get }

    #if compiler(>=6.0)
    /// The rendering mode reported by the current audio route.
    @available(iOS 17.2, *)
    var renderingMode: AVAudioSession.RenderingMode { get }
    #endif

    #if compiler(>=6.1)
    /// Whether the session requests echo-cancelled input.
    @available(iOS 18.2, *)
    var prefersEchoCancelledInput: Bool { get }
    /// Whether echo cancellation is enabled for the input.
    @available(iOS 18.2, *)
    var isEchoCancelledInputEnabled: Bool { get }
    /// Whether the input supports echo cancellation.
    @available(iOS 18.2, *)
    var isEchoCancelledInputAvailable: Bool { get }
    #endif

    /// Configures the audio session category and options.
    /// - Parameters:
    ///   - category: The audio category (e.g., `.playAndRecord`).
    ///   - mode: The audio mode (e.g., `.voiceChat`).
    ///   - categoryOptions: The options for the category (e.g., `.allowBluetoothHFP`).
    /// - Throws: An error if setting the category fails.
    func setCategory(
        _ category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        with categoryOptions: AVAudioSession.CategoryOptions
    ) throws

    /// Overrides the audio output port (e.g., to speaker).
    /// - Parameter port: The output port override.
    /// - Throws: An error if overriding fails.
    func setOverrideOutputAudioPort(
        _ port: AVAudioSession.PortOverride
    ) throws

    /// The method uses a slightly different name to avoid compiler not being able to automatically
    /// fulfil the conformance to this protocol.
    func setIsActive(_ active: Bool) throws
}

extension AVAudioSession: AVAudioSessionProtocol {
    func setIsActive(_ active: Bool) throws {
        try setActive(active)
    }
    
    func setCategory(
        _ category: Category,
        mode: Mode,
        with categoryOptions: CategoryOptions
    ) throws {
        try setCategory(
            category,
            mode: mode,
            options: categoryOptions
        )
    }
    
    func setOverrideOutputAudioPort(_ port: PortOverride) throws {
        try overrideOutputAudioPort(port)
    }
}
