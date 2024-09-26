//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A factory class for creating WebRTC-related objects such as peer connections,
/// video sources, and audio tracks.
final class PeerConnectionFactory: @unchecked Sendable {

    /// The audio processing module associated with this factory.
    private let audioProcessingModule: RTCAudioProcessingModule

    /// Lazy-loaded RTCPeerConnectionFactory instance.
    private lazy var factory: RTCPeerConnectionFactory = {
        let encoderFactory = RTCVideoEncoderFactorySimulcast(
            primary: defaultEncoder,
            fallback: defaultEncoder
        )
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        return RTCPeerConnectionFactory(
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

    /// Creates a video source, optionally configured for screen sharing.
    /// - Parameter forScreenShare: Boolean indicating if the source is for screen sharing.
    /// - Returns: An RTCVideoSource instance.
    func makeVideoSource(forScreenShare: Bool) -> RTCVideoSource {
        factory.videoSource(forScreenCast: forScreenShare)
    }

    /// Creates a video track from a given video source.
    /// - Parameter source: The RTCVideoSource to use for the track.
    /// - Returns: An RTCVideoTrack instance.
    func makeVideoTrack(source: RTCVideoSource) -> RTCVideoTrack {
        factory.videoTrack(with: source, trackId: UUID().uuidString)
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
}

/// A thread-safe storage class for managing PeerConnectionFactory instances.
final class PeerConnectionFactoryStorage {
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
