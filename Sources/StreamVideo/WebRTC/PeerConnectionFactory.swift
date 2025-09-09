//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A factory class for creating WebRTC-related objects such as peer connections,
/// video sources, and audio tracks.
final class PeerConnectionFactory: @unchecked Sendable {
    
    /// The audio processing module associated with this factory.
    private let audioProcessingModule: RTCAudioProcessingModule
    
    /// Lazy-loaded RTCPeerConnectionFactory instance.
    private(set) lazy var factory: RTCPeerConnectionFactory = {
        let encoderFactory = RTCVideoEncoderFactorySimulcast(
            primary: defaultEncoder,
            fallback: defaultEncoder
        )
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(
            audioDeviceModuleType: .platformDefault,
            bypassVoiceProcessing: false,
            encoderFactory: encoderFactory,
            decoderFactory: decoderFactory,
            audioProcessingModule: audioProcessingModule
        )
    }()
    
    /// Lazy-loaded default video encoder factory.
    private lazy var defaultEncoder = RTCDefaultVideoEncoderFactory()
    
    /// Lazy-loaded default video decoder factory.
    private lazy var defaultDecoder = RTCDefaultVideoDecoderFactory()
    
    /// Array of supported video codec information for encoding.
    var supportedVideoCodecEncoding: [RTCVideoCodecInfo] {
        defaultEncoder.supportedCodecs()
    }
    
    /// Array of supported video codec information for decoding.
    var supportedVideoCodecDecoding: [RTCVideoCodecInfo] {
        defaultDecoder.supportedCodecs()
    }

    var audioDeviceModule: RTCAudioDeviceModule { factory.audioDeviceModule }

    /// Creates or retrieves a PeerConnectionFactory instance for a given
    /// audio processing module.
    /// - Parameter audioProcessingModule: The RTCAudioProcessingModule to use.
    /// - Returns: A PeerConnectionFactory instance.
    static func build(
        audioProcessingModule: RTCAudioProcessingModule
    ) -> PeerConnectionFactory {
        if let factory = PeerConnectionFactoryStorage.shared.factory(
            for: audioProcessingModule
        ) {
            return factory
        } else {
            return .init(audioProcessingModule)
        }
    }
    
    /// Private initializer to ensure instances are created through the `build` method.
    /// - Parameter audioProcessingModule: The RTCAudioProcessingModule to use.
    private init(_ audioProcessingModule: RTCAudioProcessingModule) {
        self.audioProcessingModule = audioProcessingModule
        _ = factory
        PeerConnectionFactoryStorage.shared.store(self, for: audioProcessingModule)
    }
    
    deinit {
        PeerConnectionFactoryStorage.shared.remove(for: audioProcessingModule)
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
            Encoder preferredCodec: \(defaultEncoder.preferredCodec)
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
}

/// A thread-safe storage class for managing PeerConnectionFactory instances.
final class PeerConnectionFactoryStorage: @unchecked Sendable {
    /// Shared singleton instance of PeerConnectionFactoryStorage.
    static let shared = PeerConnectionFactoryStorage()
    
    /// Dictionary to store PeerConnectionFactory instances, keyed by module address.
    private var storage: [String: PeerConnectionFactory] = [:]
    
    /// Queue to ensure thread-safe access to the storage.
    private let queue = UnfairQueue()
    
    /// Stores a PeerConnectionFactory instance for a given RTCAudioProcessingModule.
    /// - Parameters:
    ///   - factory: The PeerConnectionFactory to store.
    ///   - module: The RTCAudioProcessingModule associated with the factory.
    func store(
        _ factory: PeerConnectionFactory,
        for module: RTCAudioProcessingModule
    ) {
        queue.sync {
            storage[key(for: module)] = factory
        }
    }
    
    /// Retrieves a PeerConnectionFactory instance for a given RTCAudioProcessingModule.
    /// - Parameter module: The RTCAudioProcessingModule to lookup.
    /// - Returns: The associated PeerConnectionFactory, if found.
    func factory(for module: RTCAudioProcessingModule) -> PeerConnectionFactory? {
        queue.sync {
            storage[key(for: module)]
        }
    }
    
    /// Removes a PeerConnectionFactory instance for a given RTCAudioProcessingModule.
    /// If the storage becomes empty after removal, it cleans up SSL.
    /// - Parameter module: The RTCAudioProcessingModule to remove.
    func remove(for module: RTCAudioProcessingModule) {
        queue.sync {
            storage[key(for: module)] = nil
            if storage.isEmpty {
                /// SSL cleanUp should only occur when no factory is active. During tests where
                /// factories are being created on demand this is causing failures. The storage ensures
                /// that only when there is no other factory the SSL will be cleaned up.
                RTCCleanupSSL()
            }
        }
    }
    
    private func key(for object: AnyObject) -> String {
        "\(Unmanaged.passUnretained(object).toOpaque())"
    }
}
