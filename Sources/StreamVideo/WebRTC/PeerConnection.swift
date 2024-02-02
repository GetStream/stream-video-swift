//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import SwiftProtobuf

enum PeerConnectionType: String {
    case subscriber
    case publisher
}

class PeerConnection: NSObject, RTCPeerConnectionDelegate, @unchecked Sendable {

    private let pc: RTCPeerConnection
    private let eventDecoder: WebRTCEventDecoder
    var signalService: Stream_Video_Sfu_Signal_SignalServer
    private let sessionId: String
    private let type: PeerConnectionType
    private let videoOptions: VideoOptions
    private(set) var transceiver: RTCRtpTransceiver?
    private(set) var transceiverScreenshare: RTCRtpTransceiver?
    internal var pendingIceCandidates = [RTCIceCandidate]()
    private var publishedTracks = [TrackType]()
    private var screensharingStreams = [RTCMediaStream]()

    var onNegotiationNeeded: ((PeerConnection, RTCMediaConstraints?) -> Void)?
    var onDisconnect: ((PeerConnection) -> Void)?
    var onConnected: ((PeerConnection) -> Void)?
    var onStreamAdded: ((RTCMediaStream) -> Void)?
    var onStreamRemoved: ((RTCMediaStream) -> Void)?

    var paused = false
    
    var connectionState: RTCPeerConnectionState {
        pc.connectionState
    }

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

    var audioTrackPublished: Bool {
        publishedTracks.contains(.audio)
    }

    var videoTrackPublished: Bool {
        publishedTracks.contains(.video)
    }

    var shouldRestartIce: Bool {
        !publishedTracks.isEmpty
    }

    func createOffer(constraints: RTCMediaConstraints = .defaultConstraints) async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { continuation in
            pc.offer(for: constraints) { sdp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sdp = sdp {
                    log.debug("""
                    Offer created
                    \(sdp.sdp)
                    """)
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
            pc.setRemoteDescription(sessionDescription) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    Task {
                        for candidate in self.pendingIceCandidates {
                            _ = try? await self.add(iceCandidate: candidate)
                        }
                        self.pendingIceCandidates = []
                        continuation.resume(returning: ())
                    }
                }
            }
        }
    }

    func addTrack(_ track: RTCMediaStreamTrack, streamIds: [String], trackType: TrackType) {
        publishedTracks.append(trackType)
        pc.add(track, streamIds: streamIds)
    }

    func addTransceiver(
        _ track: RTCMediaStreamTrack,
        streamIds: [String],
        direction: RTCRtpTransceiverDirection = .sendOnly,
        trackType: TrackType
    ) {
        let transceiverInit = RTCRtpTransceiverInit()
        transceiverInit.direction = direction
        transceiverInit.streamIds = streamIds
        transceiverInit.sendEncodings = encodingParams(for: trackType)
        publishedTracks.append(trackType)
        if trackType == .screenshare {
            if transceiverScreenshare != nil {
                transceiverScreenshare?.stopInternal()
                for screensharingStream in screensharingStreams {
                    pc.remove(screensharingStream)
                }
                screensharingStreams = []
            }
            transceiverScreenshare = pc.addTransceiver(with: track, init: transceiverInit)
        } else {
            transceiver = pc.addTransceiver(with: track, init: transceiverInit)
        }
    }

    func add(iceCandidate: RTCIceCandidate) async throws {
        guard pc.remoteDescription != nil else {
            log.debug("remote description not set, adding pending ice candidate", subsystems: .webRTC)
            pendingIceCandidates.append(iceCandidate)
            return
        }
        try await add(candidate: iceCandidate)
    }
    
    func restartIce() {
        pc.restartIce()
    }

    func close() {
        pc.close()
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        log.debug(
            "New stream added with id = \(stream.streamId) for \(type.rawValue), sfu = \(signalService.hostname)",
            subsystems: .webRTC
        )
        if stream.streamId.contains(WebRTCClient.Constants.screenshareTrackType) {
            screensharingStreams.append(stream)
        }
        onStreamAdded?(stream)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        log.debug("Stream removed from peer connection \(type.rawValue)", subsystems: .webRTC)
        onStreamRemoved?(stream)
    }

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        log.debug("Negotiation needed for peer connection \(type.rawValue)", subsystems: .webRTC)
        onNegotiationNeeded?(self, .defaultConstraints)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        func logMessage(_ level: LogLevel) {
            let message = "PeerConnection of type:\(type.rawValue) changed IceConnectionState to \(newState)"
            switch level {
            case .error:
                log.error(message, subsystems: [.webRTC])
            default:
                log.debug(message, subsystems: [.webRTC])
            }
        }

        switch newState {
        case .failed:
            logMessage(.error)
        case .disconnected:
            onDisconnect?(self)
            logMessage(.debug)
        case .connected:
            onConnected?(self)
            logMessage(.debug)
        default:
            logMessage(.debug)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        log.debug("Ice gathering state changed to \(newState)", subsystems: .webRTC)
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        log.debug("Generated ice candidate \(candidate.sdp) for \(type.rawValue)", subsystems: .webRTC)
        if paused {
            return
        }
        Task {
            let encoder = JSONEncoder()
            let iceCandidate = candidate.toIceCandidate()
            let json = try encoder.encode(iceCandidate)
            let jsonString = String(data: json, encoding: .utf8) ?? ""
            var iceTrickle = Stream_Video_Sfu_Models_ICETrickle()
            iceTrickle.iceCandidate = jsonString
            iceTrickle.sessionID = sessionId
            iceTrickle.peerType = type == .publisher ? .publisherUnspecified : .subscriber
            _ = try await signalService.iceTrickle(iCETrickle: iceTrickle)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        log.debug("Data channel opened for \(type.rawValue)", subsystems: .webRTC)
    }

    func findScreensharingTrack(for trackLookupPrefix: String?) -> RTCVideoTrack? {
        guard let trackLookupPrefix = trackLookupPrefix else { return nil }
        for stream in screensharingStreams {
            if stream.streamId.contains(trackLookupPrefix) {
                return stream.videoTracks.first
            }
        }
        return nil
    }

    func update(configuration: RTCConfiguration?) {
        guard let configuration else { return }
        pc.setConfiguration(configuration)
    }

    func statsReport() async throws -> RTCStatisticsReport {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                return continuation.resume(throwing: ClientError.Unexpected())
            }
            pc.statistics { report in
                continuation.resume(returning: report)
            }
        }
    }

    // MARK: - private

    private func encodingParams(for trackType: TrackType) -> [RTCRtpEncodingParameters] {
        var codecs = videoOptions.supportedCodecs
        var encodingParams = [RTCRtpEncodingParameters]()
        if trackType == .screenshare {
            codecs = [.screenshare]
        }
        for codec in codecs {
            let encodingParam = RTCRtpEncodingParameters()
            encodingParam.rid = codec.quality
            encodingParam.maxBitrateBps = (codec.maxBitrate) as NSNumber
            if let scaleDownFactor = codec.scaleDownFactor {
                encodingParam.scaleResolutionDownBy = (scaleDownFactor) as NSNumber
            }
            if trackType == .screenshare {
                encodingParam.isActive = true
            }
            encodingParams.append(encodingParam)
        }
        return encodingParams
    }

    @discardableResult
    private func add(candidate: RTCIceCandidate) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.pc.add(candidate) { error in
                if let error = error {
                    log.error("Error adding ice candidate", subsystems: .webRTC, error: error)
                    continuation.resume(throwing: error)
                } else {
                    log.debug("Added ice candidate successfully", subsystems: .webRTC)
                    continuation.resume(returning: true)
                }
            }
        }
    }
}

struct TrackType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension TrackType {
    static let audio: Self = "audio"
    static let video: Self = "video"
    static let screenshare: Self = "screenshare"
}

struct ICECandidate: Codable {
    let candidate: String
    let sdpMid: String?
    let sdpMLineIndex: Int32
}

extension RTCIceCandidate {

    func toIceCandidate() -> ICECandidate {
        ICECandidate(candidate: sdp, sdpMid: sdpMid, sdpMLineIndex: sdpMLineIndex)
    }
}

extension RTCVideoCodecInfo {

    func toSfuCodec() -> Stream_Video_Sfu_Models_Codec {
        var codec = Stream_Video_Sfu_Models_Codec()
        codec.name = name
        return codec
    }
}

extension RTCIceConnectionState: CustomStringConvertible {

    public var description: String {
        switch self {
        case .new:
            return "new"
        case .checking:
            return "checking"
        case .connected:
            return "connected"
        case .completed:
            return "completed"
        case .failed:
            return "failed"
        case .disconnected:
            return "disconnected"
        case .closed:
            return "closed"
        case .count:
            return "count"
        @unknown default:
            return "unknown"
        }
    }
}
