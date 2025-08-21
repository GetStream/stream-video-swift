//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A protocol defining requirements for an audio filter capture post-processing module.
public protocol AudioFilterCapturePostProcessingModule: RTCAudioCustomProcessingDelegate {

    /// Indicates whether High-Fidelity (HiFi) audio mode is enabled.
    ///
    /// When `true`, audio filtering and post-processing are bypassed to
    /// preserve the original audio quality. This is useful for music
    /// streaming and high-quality voice calls where audio fidelity is
    /// paramount over noise reduction and echo cancellation.
    var isHiFiEnabled: Bool { get set }

    /// The currently active audio filter.
    var audioFilter: AudioFilter? { get }

    /// Sets the audio filter for processing captured audio.
    /// - Parameter audioFilter: The audio filter to set.
    func setAudioFilter(_ audioFilter: AudioFilter?)
}

/// A class that handles post-processing of captured audio streams using custom audio filtering.
open class StreamAudioFilterCapturePostProcessingModule: NSObject, AudioFilterCapturePostProcessingModule, @unchecked Sendable {

    /// Controls whether High-Fidelity (HiFi) audio mode is enabled.
    ///
    /// When set to `true`, the audio processing in
    /// `audioProcessingProcess(audioBuffer:)` is bypassed, allowing the
    /// original audio to pass through without any filtering or modification.
    /// This preserves audio quality for music and high-fidelity voice calls.
    ///
    /// - Note: Defaults to `false` to enable audio filtering by default.
    public var isHiFiEnabled: Bool = true

    /// The audio filter for processing audio streams.
    public private(set) var audioFilter: AudioFilter?

    /// The sample rate for audio processing.
    public private(set) var sampleRate: Int = 0

    /// The number of audio channels for processing.
    public private(set) var channels: Int = 0

    /// Initializes a new instance of `StreamCapturePostProcessingModule`.
    override public init() {
        super.init()
    }

    // MARK: - Accessors

    /// Sets the audio filter asynchronously.
    /// - Parameter audioFilter: The audio filter to set for processing.
    open func setAudioFilter(_ audioFilter: AudioFilter?) {
        let oldValue = self.audioFilter
        oldValue?.release()

        guard oldValue?.id != audioFilter?.id else {
            return
        }

        log.debug("AudioFilter updated \(oldValue?.id ?? "nil") → \(audioFilter?.id ?? "nil")")

        if let newValue = audioFilter, sampleRate > 0, channels > 0 {
            /// If new filter is set and sample rate & channels are valid, initialize the filter.
            newValue.initialize(sampleRate: sampleRate, channels: channels)
            self.audioFilter = newValue
        } else {
            /// Set audio filter to `nil` if conditions not met.
            self.audioFilter = nil
        }
    }

    // MARK: - RTCAudioCustomProcessingDelegate

    /// Handles initialization of audio processing.
    /// - Parameters:
    ///   - sampleRateHz: The sample rate in Hz.
    ///   - channels: The number of audio channels.
    open func audioProcessingInitialize(
        sampleRate sampleRateHz: Int,
        channels: Int
    ) {
        log.debug("AudioSession updated sampleRate:\(sampleRateHz) channels:\(channels)")
        sampleRate = sampleRateHz
        self.channels = channels
        audioFilter?.initialize(
            sampleRate: sampleRateHz,
            channels: channels
        )
    }

    /// Handles audio processing on received audio buffers.
    ///
    /// This method applies the configured audio filter to the incoming audio
    /// buffer unless HiFi mode is enabled. When `isHiFiEnabled` is `true`,
    /// the method returns immediately without processing, preserving the
    /// original audio quality.
    ///
    /// - Parameter audioBuffer: The incoming audio buffer to process.
    ///
    /// - Note: Processing is skipped when either HiFi mode is enabled or no
    ///   audio filter is configured.
    open func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        guard !isHiFiEnabled else {
            return
        }

        guard let audioFilter else {
            return
        }
        var audioBuffer = audioBuffer
        audioFilter.applyEffect(to: &audioBuffer)
    }

    /// Handles release of audio processing resources.
    open func audioProcessingRelease() {
        audioFilter = nil
    }
}
