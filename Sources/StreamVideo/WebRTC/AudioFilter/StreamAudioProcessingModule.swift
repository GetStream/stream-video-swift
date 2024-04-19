//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

open class StreamAudioFilterProcessingModule: RTCDefaultAudioProcessingModule, AudioProcessingModule, @unchecked Sendable {

    public convenience init(
        config: RTCAudioProcessingConfig? = nil,
        renderPreProcessingDelegate: RTCAudioCustomProcessingDelegate? = nil
    ) {
        self.init(
            config: config,
            capturePostProcessingDelegate: StreamAudioFilterCapturePostProcessingModule(),
            renderPreProcessingDelegate: renderPreProcessingDelegate
        )
    }

    public var activeAudioFilterId: String? {
        (capturePostProcessingDelegate as? StreamAudioFilterCapturePostProcessingModule)?.activeAudioFilterId
    }

    public func setAudioFilter(
        _ filter: AudioFilter?
    ) {
        (capturePostProcessingDelegate as? StreamAudioFilterCapturePostProcessingModule)?.setAudioFilter(filter)
    }
}
