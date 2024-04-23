//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A protocol defining requirements for an audio filter capture post-processing module.
public protocol AudioFilterCapturePostProcessingModule: RTCAudioCustomProcessingDelegate {

    /// The identifier of the currently active audio filter.
    var activeAudioFilterId: String? { get }

    /// Sets the audio filter for processing captured audio.
    /// - Parameter audioFilter: The audio filter to set.
    func setAudioFilter(_ audioFilter: AudioFilter?)
}

/// A class that handles post-processing of captured audio streams using custom audio filtering.
open class StreamAudioFilterCapturePostProcessingModule: NSObject, AudioFilterCapturePostProcessingModule, @unchecked Sendable {

    /// The state actor encapsulating the module's state.
    private actor State {
        private(set) var audioFilter: AudioFilter?
        private(set) var sampleRate: Int = 0
        private(set) var channels: Int = 0

        /// Sets the audio filter for processing audio streams.
        /// - Parameter value: The audio filter to set. If not `nil`, releases the previous filter.
        func setAudioFilter(_ value: AudioFilter?) {
            audioFilter?.release() // Release the previous audio filter.
            audioFilter = value // Set the new audio filter.
        }

        /// Sets the sample rate for audio processing.
        /// - Parameter value: The sample rate value to set.
        func setSampleRate(_ value: Int) {
            self.sampleRate = value
        }

        /// Sets the number of audio channels for processing.
        /// - Parameter value: The number of audio channels value to set.
        func setChannels(_ value: Int) {
            self.channels = value
        }
    }

    /// The state instance containing audio processing state information.
    private var state: State = .init()

    public var activeAudioFilterId: String?

    /// Initializes a new instance of `StreamCapturePostProcessingModule`.
    override public init() {
        super.init()
    }

    // MARK: - Accessors

    /// Sets the audio filter asynchronously.
    /// - Parameter audioFilter: The audio filter to set for processing.
    open func setAudioFilter(_ audioFilter: AudioFilter?) {
        Task {
            let oldValue = await state.audioFilter
            let sampleRate = await state.sampleRate
            let channels = await state.channels

            guard oldValue?.id != audioFilter?.id else {
                return
            }

            log.debug("AudioFilter updated \(oldValue?.id ?? "nil") → \(audioFilter?.id ?? "nil")")

            if let newValue = audioFilter, sampleRate > 0, channels > 0 {
                /// If new filter is set and sample rate & channels are valid, initialize the filter.
                newValue.initialize(sampleRate: sampleRate, channels: channels)
                await state.setAudioFilter(newValue)
                activeAudioFilterId = newValue.id
            } else {
                /// Set audio filter to `nil` if conditions not met.
                await state.setAudioFilter(nil)
            }
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
        Task {
            await state.setSampleRate(sampleRateHz)
            await state.setChannels(channels)
            await state.audioFilter?.initialize(
                sampleRate: sampleRateHz,
                channels: channels
            )
        }
    }

    /// Handles audio processing on received audio buffers.
    /// - Parameter audioBuffer: The incoming audio buffer to process.
    open func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        Task {
            guard let audioFilter = await state.audioFilter else { return }
            var audioBuffer = audioBuffer
            audioFilter.applyEffect(to: &audioBuffer)
        }
    }

    /// Handles release of audio processing resources.
    open func audioProcessingRelease() {
        Task {
            await state.setAudioFilter(nil)
        }
    }
}
