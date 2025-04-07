//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

public final class ProximityOutputAudioSessionCapability: AudioSessionCapability, _AudioSessionCapability, @unchecked Sendable {

    public let identifier: ObjectIdentifier = .init("audio-session-proximity-call-settings" as NSString)

    private let proximityMonitor: ProximityMonitor = .init()
    private var proximityCancellable: AnyCancellable?

    var actionDispatcher: ((CallSettings) async -> Void)?
    weak var audioSession: StreamAudioSession?

    public init() {
        proximityCancellable = proximityMonitor
            .$state
            .removeDuplicates()
            .filter { [weak self] _ in self?.audioSession?.currentRoute.isExternal == false }
            .compactMap { [weak self] in self?.audioSession?.activeCallSettings.withUpdatedSpeakerState($0 == .far) }
            .sinkTask { [weak self] in await self?.actionDispatcher?($0) }
    }
}
