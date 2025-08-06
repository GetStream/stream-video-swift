//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

protocol AudioSessionProtocol: AnyObject {
    var prefersNoInterruptionsFromSystemAlerts: Bool { get }
    
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

    func perform(
        _ operation: (AudioSessionProtocol) throws -> Void
    ) throws

    func overrideOutputAudioPort(_ port: AVAudioSession.PortOverride) throws

    func setConfiguration(_ configuration: RTCAudioSessionConfiguration) throws
}
