//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A protocol defining requirements for an audio processing module that supports audio filters.
public protocol AudioProcessingModule: RTCAudioProcessingModule, Sendable {

    /// The currently active audio filter.
    var activeAudioFilter: AudioFilter? { get }

    /// Sets the audio filter to be used for audio processing.
    /// - Parameter filter: The audio filter to set.
    func setAudioFilter(_ filter: AudioFilter?)
}

/// A custom audio processing module that integrates with an audio filter for stream processing.
///
/// - Important: It seems that ``RTCDefaultAudioProcessingModule`` has a bug on release
/// which causes a crash. As a workaround for now we create and instance of
/// ``StreamAudioFilterProcessingModule`` and cache it in the `InjectedValues` for reuse.
open class StreamAudioFilterProcessingModule: RTCDefaultAudioProcessingModule, AudioProcessingModule, @unchecked Sendable {

    private let _capturePostProcessingDelegate: AudioFilterCapturePostProcessingModule

    /// Initializes a new instance of `StreamAudioFilterProcessingModule`.
    /// - Parameters:
    ///   - config: Optional configuration for audio processing.
    ///   - renderPreProcessingDelegate: Optional delegate for render pre-processing.
    public init(
        config: RTCAudioProcessingConfig? = nil,
        capturePostProcessingDelegate: AudioFilterCapturePostProcessingModule = StreamAudioFilterCapturePostProcessingModule(),
        renderPreProcessingDelegate: RTCAudioCustomProcessingDelegate? = nil
    ) {
//        #if STREAM_TESTS
//        assert(
//            false,
//            "\(type(of: self)) should not be used in Tests as it relies on the WebRTC stack being fully setup. Consider using `VideoConfig.dummy()` when initializing StreamVideo in tests or `MockAudioProcessingModule` if you need to use an instance directly."
//        )
//        #endif
        _capturePostProcessingDelegate = capturePostProcessingDelegate
        super.init(
            config: config,
            capturePostProcessingDelegate: capturePostProcessingDelegate,
            renderPreProcessingDelegate: renderPreProcessingDelegate
        )
    }
    
    override public func apply(_ config: RTCAudioProcessingConfig) {
        super.apply(config)
    }

    /// Retrieves the identifier of the currently active audio filter.
    public var activeAudioFilter: AudioFilter? {
        _capturePostProcessingDelegate.audioFilter
    }

    /// Sets the audio filter for stream processing.
    /// - Parameter filter: The audio filter to set.
    public func setAudioFilter(_ filter: AudioFilter?) {
        _capturePostProcessingDelegate.setAudioFilter(filter)
    }
}

enum AudioProcessingModuleKey: InjectionKey {
    nonisolated(unsafe) public static var currentValue: AudioProcessingModule = StreamAudioFilterProcessingModule()
}

extension InjectedValues {
    var audioFilterProcessingModule: AudioProcessingModule {
        get { Self[AudioProcessingModuleKey.self] }
        set { Self[AudioProcessingModuleKey.self] = newValue }
    }
}
