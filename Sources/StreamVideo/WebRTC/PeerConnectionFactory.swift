//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A factory class for creating WebRTC-related objects such as peer connections,
/// video sources, and audio tracks.
final class PeerConnectionFactory: @unchecked Sendable {
    
    /// The audio processing module associated with this factory.
    private let audioProcessingModule: RTCAudioProcessingModule

    /// An optional native audio device used instead of WebRTC's default audio
    /// engine.
    ///
    /// Custom environments can provide a device that avoids creating the
    /// platform audio engine. When `nil`, the factory retains its standard
    /// production audio pipeline and applies ``audioProcessingModule``.
    private let audioDevice: RTCAudioDevice?

    /// Backing storage for the audio device module.
    ///
    /// Kept optional so we can release it explicitly in `deinit` before
    /// `factory` is torn down.
    private var audioDeviceModuleStorage: AudioDeviceModule?

    /// Wrapper around WebRTC's audio device module.
    var audioDeviceModule: AudioDeviceModule {
        guard let audioDeviceModuleStorage else {
            preconditionFailure("AudioDeviceModule unavailable.")
        }
        return audioDeviceModuleStorage
    }
    
    /// The underlying WebRTC factory configured with either the injected audio
    /// device or the default production audio engine.
    private(set) lazy var factory: RTCPeerConnectionFactory = {
        let encoderFactory = RTCVideoEncoderFactorySimulcast(
            primary: Self.defaultEncoder,
            fallback: Self.defaultEncoder
        )
        if let audioDevice {
            return RTCPeerConnectionFactory(
                encoderFactory: encoderFactory,
                decoderFactory: Self.defaultDecoder,
                audioDevice: audioDevice
            )
        }
        return RTCPeerConnectionFactory(
            audioDeviceModuleType: .audioEngine,
            bypassVoiceProcessing: false,
            encoderFactory: encoderFactory,
            decoderFactory: Self.defaultDecoder,
            audioProcessingModule: audioProcessingModule
        )
    }()
    
    /// Lazy-loaded default video encoder factory.
    private nonisolated(unsafe) static let defaultEncoder = RTCDefaultVideoEncoderFactory()

    /// Lazy-loaded default video decoder factory.
    private nonisolated(unsafe) static let defaultDecoder = RTCDefaultVideoDecoderFactory()

    /// Array of supported video codec information for encoding.
    var supportedVideoCodecEncoding: [RTCVideoCodecInfo] {
        Self.defaultEncoder.supportedCodecs()
    }
    
    /// Array of supported video codec information for decoding.
    var supportedVideoCodecDecoding: [RTCVideoCodecInfo] {
        Self.defaultDecoder.supportedCodecs()
    }

    /// Creates a peer-connection factory with the requested audio pipeline.
    ///
    /// - Parameters:
    ///   - audioProcessingModule: The processing module used by the default
    ///     WebRTC audio engine.
    ///   - audioDeviceModuleSource: An optional controller backing the SDK's
    ///     ``AudioDeviceModule`` wrapper. Provide it with `audioDevice` because
    ///     WebRTC does not expose its audio-device module when initialized with
    ///     a custom native device.
    ///   - audioDevice: An optional native device that replaces WebRTC's
    ///     default audio engine.
    /// - Returns: A PeerConnectionFactory instance.
    static func build(
        audioProcessingModule: RTCAudioProcessingModule,
        audioDeviceModuleSource: RTCAudioDeviceModuleControlling? = nil,
        audioDevice: RTCAudioDevice? = nil
    ) -> PeerConnectionFactory {
        .init(
            audioProcessingModule,
            audioDeviceModuleSource: audioDeviceModuleSource,
            audioDevice: audioDevice
        )
    }
    
    /// Initializes a peer-connection factory with matching native and SDK audio
    /// device implementations.
    ///
    /// - Parameters:
    ///   - audioProcessingModule: The processing module used by the default
    ///     WebRTC audio engine.
    ///   - audioDeviceModuleSource: An optional controller used by the SDK's
    ///     audio-device wrapper.
    ///   - audioDevice: An optional native device used to construct WebRTC's
    ///     peer-connection factory.
    private init(
        _ audioProcessingModule: RTCAudioProcessingModule,
        audioDeviceModuleSource: RTCAudioDeviceModuleControlling?,
        audioDevice: RTCAudioDevice?
    ) {
        self.audioProcessingModule = audioProcessingModule
        self.audioDevice = audioDevice
        _ = factory

        if let audioDeviceModuleSource {
            audioDeviceModuleStorage = .init(audioDeviceModuleSource)
        } else {
            audioDeviceModuleStorage = .init(factory.audioDeviceModule)
        }
    }

    deinit {
        /// `RTCAudioDeviceModule` keeps a raw pointer to WebRTC's worker
        /// thread. Releasing it while `factory` is still alive prevents
        /// dangling-pointer dereferences during module deallocation.
        audioDeviceModuleStorage = nil
    }

    // MARK: - Builders
    
    /// Creates a video source, optionally configured for screen sharing.
    /// - Parameter forScreenShare: Boolean indicating if the source is for screen sharing.
    /// - Returns: An RTCVideoSource instance.
    func makeVideoSource(forScreenShare: Bool) -> RTCVideoSource {
        let result = factory.videoSource(forScreenCast: forScreenShare)
        log.debug(
            """
            VideoSource was created \(Unmanaged.passUnretained(result).toOpaque())
            Encoder preferredCodec: \(Self.defaultEncoder.preferredCodec)
            """,
            subsystems: .webRTC
        )
        return result
    }
    
    /// Creates a video track from a given video source.
    /// - Parameter source: The RTCVideoSource to use for the track.
    /// - Returns: An RTCVideoTrack instance.
    func makeVideoTrack(source: RTCVideoSource) -> RTCVideoTrack {
        let result = factory.videoTrack(with: source, trackId: UUID().uuidString)
        log.debug(
            """
            VideoTrack was created \(Unmanaged.passUnretained(result).toOpaque())
            trackId: \(result.trackId)
            """,
            subsystems: .webRTC
        )
        return result
    }
    
    /// Creates an audio source with optional constraints.
    /// - Parameter constraints: Optional RTCMediaConstraints for the audio source.
    /// - Returns: An RTCAudioSource instance.
    func makeAudioSource(_ constraints: RTCMediaConstraints?) -> RTCAudioSource {
        let result = factory.audioSource(with: constraints)
        log.debug(
            """
            AudioSource was created \(Unmanaged.passUnretained(result).toOpaque())
            """,
            subsystems: .webRTC
        )
        return result
    }
    
    /// Creates an audio track from a given audio source.
    /// - Parameter source: The RTCAudioSource to use for the track.
    /// - Returns: An RTCAudioTrack instance.
    func makeAudioTrack(source: RTCAudioSource) -> RTCAudioTrack {
        let result = factory.audioTrack(with: source, trackId: UUID().uuidString)
        log.debug(
            """
            AudioTrack was created \(Unmanaged.passUnretained(result).toOpaque())
            trackId: \(result.trackId)
            """,
            subsystems: .webRTC
        )
        return result
    }

    /// Creates a peer connection with the specified configuration, constraints, and delegate.
    /// - Parameters:
    ///   - configuration: The RTCConfiguration to use.
    ///   - constraints: The RTCMediaConstraints to apply.
    ///   - delegate: The RTCPeerConnectionDelegate to set.
    /// - Throws: ClientError.Unexpected if the peer connection creation fails.
    /// - Returns: An RTCPeerConnection instance.
    func makePeerConnection(
        configuration: RTCConfiguration,
        constraints: RTCMediaConstraints,
        delegate: RTCPeerConnectionDelegate?
    ) throws -> RTCPeerConnection {
        guard let peerConnection = factory.peerConnection(
            with: configuration,
            constraints: constraints,
            delegate: delegate
        ) else {
            throw ClientError.Unexpected()
        }
        
        return peerConnection
    }
    
    // MARK: - Capabilities
    
    /// Retrieves codec capabilities for a specific audio codec.
    ///
    /// - Parameter audioCodec: The `AudioCodec` for which to fetch codec capabilities.
    /// - Returns: An `RTCRtpCodecCapability` instance if the codec is supported,
    ///   or `nil` if no matching capability is found.
    ///
    /// ## Overview
    /// This method queries the audio codec capabilities available in the underlying
    /// WebRTC framework for use in RTP (Real-Time Protocol) streaming. It ensures
    /// that only the baseline configuration of the codec is returned.
    ///
    /// ## Example
    /// ```swift
    /// if let capability = factory.codecCapabilities(for: .opus) {
    ///     print("Supports Opus codec with capability: \(capability)")
    /// }
    /// ```
    func codecCapabilities(
        for audioCodec: AudioCodec
    ) -> RTCRtpCodecCapability? {
        factory
            .rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindAudio)
            .codecs
            .baseline(for: audioCodec)
    }
    
    /// Retrieves codec capabilities for a specific video codec.
    ///
    /// - Parameter videoCodec: The `VideoCodec` for which to fetch codec capabilities.
    /// - Returns: An `RTCRtpCodecCapability` instance if the codec is supported,
    ///   or `nil` if no matching capability is found.
    ///
    /// ## Overview
    /// This method queries the video codec capabilities available in the underlying
    /// WebRTC framework for use in RTP (Real-Time Protocol) streaming. It ensures
    /// that only the baseline configuration of the codec is returned.
    ///
    /// ## Example
    /// ```swift
    /// if let capability = factory.codecCapabilities(for: .h264) {
    ///     print("Supports H.264 codec with capability: \(capability)")
    /// }
    /// ```
    func codecCapabilities(
        for videoCodec: VideoCodec
    ) -> RTCRtpCodecCapability? {
        factory
            .rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindVideo)
            .codecs
            .baseline(for: videoCodec)
    }

    // MARK: - Frame Buffer Policy

    func setFrameBufferPolicy(_ policy: RTCFrameBufferPolicy) {
        factory.frameBufferPolicy = policy
    }
}
