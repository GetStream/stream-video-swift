//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A protocol defining requirements for an audio processing module that supports audio filters.
public protocol AudioProcessingModule: RTCAudioProcessingModule, Sendable {

    /// The identifier of the currently active audio filter.
    var activeAudioFilterId: String? { get }

    /// Sets the audio filter to be used for audio processing.
    /// - Parameter filter: The audio filter to set.
    func setAudioFilter(_ filter: AudioFilter?)
}

/// A custom audio processing module that integrates with an audio filter for stream processing.
open class StreamAudioFilterProcessingModule: NSObject, RTCAudioProcessingModule, AudioProcessingModule, @unchecked Sendable {

    /// The actual processingModule.
    private let processingModule: RTCDefaultAudioProcessingModule

    /// Initializes a new instance of `StreamAudioFilterProcessingModule`.
    /// - Parameters:
    ///   - config: Optional configuration for audio processing.
    ///   - renderPreProcessingDelegate: Optional delegate for render pre-processing.
    public init(
        config: RTCAudioProcessingConfig? = nil,
        capturePostProcessingDelegate: AudioFilterCapturePostProcessingModule? = nil,
        renderPreProcessingDelegate: RTCAudioCustomProcessingDelegate? = nil
    ) {
        processingModule = .init(
            config: config,
            capturePostProcessingDelegate: capturePostProcessingDelegate,
            renderPreProcessingDelegate: renderPreProcessingDelegate
        )
    }

    public func apply(_ config: RTCAudioProcessingConfig) {
        processingModule.apply(config)
    }

    /// Retrieves the identifier of the currently active audio filter.
    public var activeAudioFilterId: String? {
        // Delegates the retrieval to the capture post-processing delegate.
        (processingModule.capturePostProcessingDelegate as? AudioFilterCapturePostProcessingModule)?.activeAudioFilterId
    }

    /// Sets the audio filter for stream processing.
    /// - Parameter filter: The audio filter to set.
    public func setAudioFilter(_ filter: AudioFilter?) {
        /// Delegates the setting of audio filter to the capture post-processing delegate.
        (processingModule.capturePostProcessingDelegate as? AudioFilterCapturePostProcessingModule)?.setAudioFilter(filter)
    }
}
