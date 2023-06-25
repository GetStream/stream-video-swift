//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
    var signalService: Stream_Video_Sfu_Signal_SignalServer
    private let sessionId: String
    private let callCid: String
    private let type: PeerConnectionType
    private let videoOptions: VideoOptions
    private let syncQueue = DispatchQueue(label: "PeerConnectionQueue", qos: .userInitiated)
    private let reportStats: Bool
    private var statsTimer: Foundation.Timer?
    private(set) var transceiver: RTCRtpTransceiver?
    private var pendingIceCandidates = [RTCIceCandidate]()
    private var publishedTracks = [TrackType]()
    private var screensharingStreams = [RTCMediaStream]()
        
    var onNegotiationNeeded: ((PeerConnection) -> Void)?
    var onDisconnect: ((PeerConnection) -> Void)?
    var onStreamAdded: ((RTCMediaStream) -> Void)?
    var onStreamRemoved: ((RTCMediaStream) -> Void)?
    
    var paused = false
    
    init(
        sessionId: String,
        callCid: String,
        pc: RTCPeerConnection,
        type: PeerConnectionType,
        signalService: Stream_Video_Sfu_Signal_SignalServer,
        videoOptions: VideoOptions,
        reportStats: Bool = false
    ) {
        self.sessionId = sessionId
        self.pc = pc
        self.signalService = signalService
        self.type = type
        self.reportStats = reportStats
        self.videoOptions = videoOptions
        self.callCid = callCid
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
    
    func createOffer(constraints: RTCMediaConstraints = .defaultConstraints) async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { continuation in
            pc.offer(for: constraints) { sdp, error in
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
        publishedTracks.append(trackType)
        transceiver = pc.addTransceiver(with: track, init: transceiverInit)
    }
    
    func add(iceCandidate: RTCIceCandidate) {
        guard pc.remoteDescription != nil else {
            log.debug("remote description not set, adding pending ice candidate")
            pendingIceCandidates.append(iceCandidate)
            return
        }
        pc.add(iceCandidate) { error in
            if let error = error {
                log.debug("Error adding ice candidate \(error.localizedDescription)")
            } else {
                log.debug("Added ice candidate successfully")
            }
        }
    }
    
    func close() {
        pc.close()
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        log.debug("New stream added with id = \(stream.streamId) for \(type.rawValue)")
        if stream.streamId.contains(WebRTCClient.Constants.screenshareTrackType) {
            screensharingStreams.append(stream)
        }
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
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        log.debug("Peer connection state changed to \(newState)")
        if newState == .disconnected {
            log.debug("Peer connection disconnected")
            onDisconnect?(self)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        log.debug("Ice gathering state changed to \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        log.debug("Generated ice candidate \(candidate.sdp) for \(type.rawValue)")
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
        log.debug("Data channel opened for \(type.rawValue)")
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
        self.pc.setConfiguration(configuration)
    }
    
    // MARK: - private
    
    private func setupStatsTimer() {
        if reportStats {
            statsTimer = Foundation.Timer.scheduledTimer(
                withTimeInterval: 15.0,
                repeats: true,
                block: { [weak self] _ in
                    self?.reportCurrentStats()
                }
            )
        }
    }
    
    private func reportCurrentStats() {
        pc.statistics(completionHandler: { _ in
            log.debug("Stats still not reported")
            /*
             Task {
                 let stats = report.statistics
                 var updated = [String: Any]()
                 for (key, value) in stats {
                     let mapped = [
                         "id": value.id,
                         "type": value.type,
                         "timestamp_us": value.timestamp_us,
                         "values": value.values
                     ]
                     updated[key] = mapped
                 }
                 guard let jsonData = try? JSONSerialization.data(
                     withJSONObject: updated,
                     options: .prettyPrinted
                 ) else { return }
                  var request = Stream_Video_Coordinator_ClientV1Rpc_ReportCallStatsRequest()
                  request.callCid = self.callCid
                  request.statsJson = jsonData
                  do {
                      _ = try await self.coordinatorService.reportCallStats(
                          reportCallStatsRequest: request
                      )
                      log.debug("successfully sent stats for \(self.type)")
                  } catch {
                      log.error("error reporting stats for \(self.type)")
                  }
             }
              */
        })
    }
    
    @discardableResult
    private func add(iceCandidate: RTCIceCandidate) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.pc.add(iceCandidate) { error in
                if let error = error {
                    log.debug("Error adding ice candidate \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                } else {
                    log.debug("Added ice candidate successfully")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    deinit {
        statsTimer?.invalidate()
        statsTimer = nil
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
