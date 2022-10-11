//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf
import WebRTC

enum PeerConnectionType: String {
    case subscriber
    case publisher
}

class PeerConnection: NSObject, RTCPeerConnectionDelegate, @unchecked Sendable {
    
    private let pc: RTCPeerConnection
    private let eventDecoder: WebRTCEventDecoder
    private let signalService: Stream_Video_Sfu_Signal_SignalServer
    private let sessionId: String
    private let type: PeerConnectionType
    private let videoOptions: VideoOptions
    private let syncQueue = DispatchQueue(label: "PeerConnectionQueue", qos: .userInitiated)
    private(set) var transceiver: RTCRtpTransceiver?
        
    var onNegotiationNeeded: ((PeerConnection) -> Void)?
    var onStreamAdded: ((RTCMediaStream) -> Void)?
    var onStreamRemoved: ((RTCMediaStream) -> Void)?
    
    init(
        sessionId: String,
        pc: RTCPeerConnection,
        type: PeerConnectionType,
        signalService: Stream_Video_Sfu_Signal_SignalServer,
        videoOptions: VideoOptions
    ) {
        self.sessionId = sessionId
        self.pc = pc
        self.signalService = signalService
        self.type = type
        self.videoOptions = videoOptions
        eventDecoder = WebRTCEventDecoder()
        super.init()
        self.pc.delegate = self
    }
    
    func makeDataChannel(label: String) throws -> DataChannel {
        let configuration = RTCDataChannelConfiguration()
        guard let dataChannel = pc.dataChannel(forLabel: label, configuration: configuration) else {
            throw ClientError.NetworkError()
        }
        return DataChannel(dataChannel: dataChannel, eventDecoder: eventDecoder)
    }
    
    func createOffer() async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { continuation in
            pc.offer(for: .defaultConstraints) { sdp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sdp = sdp {
                    continuation.resume(returning: sdp)
                } else {
                    continuation.resume(throwing: ClientError.Unknown())
                }
            }
        }
    }
    
    func createAnswer() async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { continuation in
            pc.answer(for: .defaultConstraints) { sdp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sdp = sdp {
                    continuation.resume(returning: sdp)
                } else {
                    continuation.resume(throwing: ClientError.Unknown())
                }
            }
        }
    }
    
    func setLocalDescription(_ sdp: RTCSessionDescription?) async throws {
        guard let sdp = sdp else {
            throw ClientError.Unexpected() // TODO: add appropriate errors
        }
        return try await withCheckedThrowingContinuation { continuation in
            pc.setLocalDescription(sdp) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func setRemoteDescription(_ sdp: String, type: RTCSdpType) async throws {
        let sessionDescription = RTCSessionDescription(type: type, sdp: sdp)
        return try await withCheckedThrowingContinuation { continuation in
            pc.setRemoteDescription(sessionDescription) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func addTrack(_ track: RTCMediaStreamTrack, streamIds: [String]) {
        pc.add(track, streamIds: streamIds)
    }
    
    func addTransceiver(_ track: RTCMediaStreamTrack, streamIds: [String]) {
        let transceiverInit = RTCRtpTransceiverInit()
        transceiverInit.direction = .sendOnly
        transceiverInit.streamIds = streamIds
        
        var encodingParams = [RTCRtpEncodingParameters]()
        
        for codec in videoOptions.supportedCodecs {
            let encodingParam = RTCRtpEncodingParameters()
            encodingParam.rid = codec.quality
            encodingParam.maxBitrateBps = (codec.maxBitrate) as NSNumber
            if let scaleDownFactor = codec.scaleDownFactor {
                encodingParam.scaleResolutionDownBy = (scaleDownFactor) as NSNumber
            }
            encodingParams.append(encodingParam)
        }
        
        transceiverInit.sendEncodings = encodingParams
        
        syncQueue.async { [weak self] in
            self?.transceiver = self?.pc.addTransceiver(with: track, init: transceiverInit)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        log.debug("New stream added with id = \(stream.streamId) for \(type.rawValue)")
        onStreamAdded?(stream)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        log.debug("Stream removed from peer connection \(type.rawValue)")
        onStreamRemoved?(stream)
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        log.debug("Negotiation needed for peer connection \(type.rawValue)")
        onNegotiationNeeded?(self)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        log.debug("Generated ice candidate \(candidate.sdp) for \(type.rawValue)")
        Task {
            var request = Stream_Video_Sfu_Signal_IceCandidateRequest()
            request.publisher = type == .publisher
            request.candidate = candidate.sdp
            request.sdpMid = candidate.sdpMid ?? ""
            request.sdpMlineIndex = UInt32(candidate.sdpMLineIndex)
            request.sessionID = sessionId
            _ = try await signalService.sendIceCandidate(iceCandidateRequest: request)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        log.debug("Data channel opened for \(type.rawValue)")
    }
}

extension RTCVideoCodecInfo {
    
    func toSfuCodec() -> Stream_Video_Sfu_Models_Codec {
        var codec = Stream_Video_Sfu_Models_Codec()
        codec.mime = name
        codec.hwAccelerated = name == "H264"
        return codec
    }
}
