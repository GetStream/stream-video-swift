//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

protocol PeerConnectionFactory: Sendable {

    var supportedVideoCodecEncoding: [RTCVideoCodecInfo] { get }

    var supportedVideoCodecDecoding: [RTCVideoCodecInfo] { get }

    var audioDeviceModule: RTCAudioDeviceModule { get }

    static func build(
        audioProcessingModule: RTCAudioProcessingModule
    ) -> PeerConnectionFactory

    func makeVideoSource(forScreenShare: Bool) -> RTCVideoSource

    func makeVideoTrack(source: RTCVideoSource) -> RTCVideoTrack

    func makeAudioSource(_ constraints: RTCMediaConstraints?) -> RTCAudioSource

    func makeAudioTrack(source: RTCAudioSource) -> RTCAudioTrack

    func makePeerConnection(
        configuration: RTCConfiguration,
        constraints: RTCMediaConstraints,
        delegate: RTCPeerConnectionDelegate?
    ) throws -> RTCPeerConnection

    func codecCapabilities(
        for audioCodec: AudioCodec
    ) -> RTCRtpCodecCapability?

    func codecCapabilities(
        for videoCodec: VideoCodec
    ) -> RTCRtpCodecCapability?
}
