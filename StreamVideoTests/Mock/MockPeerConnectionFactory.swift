//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import enum StreamVideo.AudioCodec
import StreamWebRTC

final class MockPeerConnectionFactory: Mockable, PeerConnectionFactory, @unchecked Sendable {

    // MARK: - Properties

    nonisolated(unsafe) private static let factory = RTCPeerConnectionFactory(
        bypassVoiceProcessing: false,
        encoderFactory: RTCVideoEncoderFactorySimulcast(
            primary: RTCDefaultVideoEncoderFactory(),
            fallback: RTCDefaultVideoEncoderFactory()
        ),
        decoderFactory: RTCDefaultVideoDecoderFactory(),
        audioProcessingModule: MockAudioProcessingModule.shared
    )
    private var peerConnection: RTCPeerConnection?

    // MARK: - Lifecycle

    init() {}

    // MARK: - Mockable

    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = MockFunctionInputKey

    enum MockFunctionKey: Hashable, CaseIterable {
        case build
        case makeVideoSource
        case makeVideoTrack
        case makeAudioSource
        case makeAudioTrack
        case makePeerConnection
        case codecCapabilitiesForAudioCodec
        case codecCapabilitiesForVideoCodec
    }

    enum MockFunctionInputKey: Payloadable {
        case build(RTCAudioProcessingModule)
        case makeVideoSource(forScreenShare: Bool)
        case makeVideoTrack(RTCVideoSource)
        case makeAudioSource(RTCMediaConstraints?)
        case makeAudioTrack(RTCAudioSource)
        case makePeerConnection(
            RTCConfiguration,
            RTCMediaConstraints,
            RTCPeerConnectionDelegate?
        )
        case codecCapabilitiesForAudioCodec(AudioCodec)
        case codecCapabilitiesForVideoCodec(VideoCodec)

        var payload: Any {
            switch self {
            case let .build(input):
                return input

            case let .makeVideoSource(input):
                return input

            case let .makeVideoTrack(input):
                return input

            case let .makeAudioSource(input):
                return input as Any

            case let .makeAudioTrack(input):
                return input

            case let .makePeerConnection(configuration, constraints, delegate):
                return (configuration, constraints, delegate)

            case let .codecCapabilitiesForAudioCodec(input):
                return input

            case let .codecCapabilitiesForVideoCodec(input):
                return input
            }
        }
    }

    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    @Atomic var stubbedFunctionInput: [FunctionKey: [MockFunctionInputKey]] = MockPeerConnectionFactory.initialStubbedFunctionInput

    // MARK: - PeerConnectionFactory

    var supportedVideoCodecEncoding: [RTCVideoCodecInfo] = []

    var supportedVideoCodecDecoding: [RTCVideoCodecInfo] = []

    var audioDeviceModule: RTCAudioDeviceModule { Self.factory.audioDeviceModule }

    static func build(
        audioProcessingModule: RTCAudioProcessingModule
    ) -> PeerConnectionFactory {
        let result = MockPeerConnectionFactory()
        result.record(.build, input: .build(audioProcessingModule))
        return result
    }

    func makeVideoSource(forScreenShare: Bool) -> RTCVideoSource {
        record(.makeVideoSource, input: .makeVideoSource(forScreenShare: forScreenShare))
        return Self.factory.videoSource(forScreenCast: forScreenShare)
    }

    func makeVideoTrack(source: RTCVideoSource) -> RTCVideoTrack {
        record(.makeVideoTrack, input: .makeVideoTrack(source))
        return Self.factory.videoTrack(with: source, trackId: .unique)
    }

    func makeAudioSource(
        _ constraints: RTCMediaConstraints?
    ) -> RTCAudioSource {
        record(.makeAudioSource, input: .makeAudioSource(constraints))
        return Self.factory.audioSource(with: constraints)
    }

    func makeAudioTrack(source: RTCAudioSource) -> RTCAudioTrack {
        record(.makeAudioTrack, input: .makeAudioTrack(source))
        return Self.factory.audioTrack(with: source, trackId: .unique)
    }

    func makePeerConnection(
        configuration: RTCConfiguration,
        constraints: RTCMediaConstraints,
        delegate: (any RTCPeerConnectionDelegate)?
    ) throws -> RTCPeerConnection {
        record(
            .makePeerConnection,
            input: .makePeerConnection(configuration, constraints, delegate)
        )

        guard
            let peerConnection = Self.factory.peerConnection(
                with: configuration,
                constraints: constraints,
                delegate: delegate
            ) else {
            throw ClientError.Unexpected()
        }

        return peerConnection
    }

    func codecCapabilities(
        for audioCodec: AudioCodec
    ) -> RTCRtpCodecCapability? {
        record(
            .codecCapabilitiesForAudioCodec,
            input: .codecCapabilitiesForAudioCodec(audioCodec)
        )
        return Self
            .factory
            .rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindAudio)
            .codecs
            .baseline(for: audioCodec)
    }

    func codecCapabilities(
        for videoCodec: VideoCodec
    ) -> RTCRtpCodecCapability? {
        record(
            .codecCapabilitiesForVideoCodec,
            input: .codecCapabilitiesForVideoCodec(videoCodec)
        )
        return Self
            .factory
            .rtpSenderCapabilities(forKind: kRTCMediaStreamTrackKindVideo)
            .codecs
            .baseline(for: videoCodec)
    }

    // MARK: - Helpers

    func mockAudioTrack() -> RTCAudioTrack {
        makeAudioTrack(
            source: makeAudioSource(.defaultConstraints)
        )
    }

    func mockVideoTrack(forScreenShare: Bool) -> RTCVideoTrack {
        makeVideoTrack(
            source: makeVideoSource(forScreenShare: forScreenShare)
        )
    }

    func mockMediaStream(
        streamID: String = UUID().uuidString
    ) -> RTCMediaStream {
        Self.factory.mediaStream(withStreamId: streamID)
    }

    func mockTransceiver(
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        audioOptions: PublishOptions.AudioPublishOptions
    ) throws -> RTCRtpTransceiver {
        if peerConnection == nil {
            peerConnection = try makePeerConnection(
                configuration: .init(),
                constraints: .defaultConstraints,
                delegate: nil
            )
        }

        return peerConnection!.addTransceiver(
            of: .audio,
            init: RTCRtpTransceiverInit(
                direction: direction,
                streamIds: streamIds,
                audioOptions: audioOptions
            )
        )!
    }

    func mockTransceiver(
        of trackType: TrackType,
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        videoOptions: PublishOptions.VideoPublishOptions
    ) throws -> RTCRtpTransceiver {
        if peerConnection == nil {
            peerConnection = try makePeerConnection(
                configuration: .init(),
                constraints: .defaultConstraints,
                delegate: nil
            )
        }

        return peerConnection!.addTransceiver(
            of: .video,
            init: RTCRtpTransceiverInit(
                trackType: trackType,
                direction: direction,
                streamIds: streamIds,
                videoOptions: videoOptions
            )
        )!
    }
}
