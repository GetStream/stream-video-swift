//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

protocol AVAudioSessionProtocol {

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
