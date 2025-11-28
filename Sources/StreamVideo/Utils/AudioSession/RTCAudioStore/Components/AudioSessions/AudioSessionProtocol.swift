//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

/// Abstraction over the WebRTC audio session that lets the store coordinate
/// audio behaviour without tying tests to the concrete implementation.
protocol AudioSessionProtocol: AnyObject {
    var avSession: AVAudioSessionProtocol { get }

    /// Indicates whether the system should suppress interruption alerts while
    /// the session is active.
    var prefersNoInterruptionsFromSystemAlerts: Bool { get }
    
    /// Toggles preference for system interruption suppression.
    /// - Parameter newValue: `true` to suppress alerts, `false` otherwise.
    func setPrefersNoInterruptionsFromSystemAlerts(_ newValue: Bool) throws

    var isActive: Bool { get }

    func setActive(_ isActive: Bool) throws

    var isAudioEnabled: Bool { get set }

    var useManualAudio: Bool { get set }

    var category: String { get }

    var mode: String { get }

    var categoryOptions: AVAudioSession.CategoryOptions { get }

    var recordPermissionGranted: Bool { get }

    func requestRecordPermission() async -> Bool

    var currentRoute: AVAudioSessionRouteDescription { get }

    func add(_ delegate: RTCAudioSessionDelegate)

    func remove(_ delegate: RTCAudioSessionDelegate)

    func audioSessionDidActivate(_ audioSession: AVAudioSession)

    func audioSessionDidDeactivate(_ audioSession: AVAudioSession)

    /// Executes an operation while the session lock is held.
    /// - Parameter operation: Closure that receives a locked `AudioSessionProtocol`.
    func perform(
        _ operation: (AudioSessionProtocol) throws -> Void
    ) throws

    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) throws

    func setPreferredOutputNumberOfChannels(_ noOfChannels: Int) throws

    /// Applies the provided configuration to the audio session.
    /// - Parameter configuration: Desired audio session configuration.
    func setConfiguration(_ configuration: RTCAudioSessionConfiguration) throws

    /// Applies the provided configuration to the audio session while optionally
    /// restoring the active state.
    /// - Parameters:
    ///   - configuration: Desired audio session configuration.
    ///   - active: When `true`, the session should be reactivated after applying
    ///     the configuration.
    func setConfiguration(
        _ configuration: RTCAudioSessionConfiguration,
        active: Bool
    ) throws
}

extension AudioSessionProtocol {

    func setConfiguration(
        _ configuration: RTCAudioSessionConfiguration,
        active: Bool
    ) throws {
        try setConfiguration(configuration)

        guard active else { return }

        try setActive(true)
    }
}
