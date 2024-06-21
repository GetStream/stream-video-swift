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
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) was created.
            SignalService:\(signalService.hostname)
            SessionId:\(sessionId)
            PreferredFps: \(videoOptions.preferredFps)
            SupportedCodecs: \(videoOptions.supportedCodecs.map(\.quality))
            PreferredDimensions: \(videoOptions.preferredDimensions)
            PreferredFormat: \(videoOptions.preferredFormat?.description ?? "nil")
            """,
            subsystems: .peerConnection
        )
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

    func createOffer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) is creating offer.
            Constraints: \(constraints)
            """,
            subsystems: .peerConnection
        )

        return try await withCheckedThrowingContinuation { [type] continuation in
            pc.offer(for: constraints) {
                sdp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sdp = sdp {
                    log.debug(
                        """
                        PeerConnection of type:\(type.rawValue) created offer.
                        SDP: \(sdp.description)
                        Constraints: \(constraints)
                        """,
                        subsystems: .peerConnection
                    )
                    continuation.resume(returning: sdp)
                } else {
                    continuation.resume(
                        throwing: ClientError.Unknown(
                            "PeerConnection of type:\(type.rawValue) failed to create offer."
                        )
                    )
                }
            }
        }
    }

    func createAnswer() async throws -> RTCSessionDescription {
        log.debug(
            "PeerConnection of type:\(type.rawValue) is creating answer.",
            subsystems: .peerConnection
        )

        return try await withCheckedThrowingContinuation { continuation in
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
            throw ClientError.Unexpected(
                """
                PeerConnection of type:\(type.rawValue) cannot set localDescription
                because SDP isn't available.
                """
            ) // TODO: add appropriate errors
        }
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) is setting localDescription
            SDP: \(sdp)
            """,
            subsystems: .peerConnection
        )
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
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) is setting remoteDescription
            Type: \(type)
            SDP: \(sdp)
            """,
            subsystems: .peerConnection
        )

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

    func addTrack(
        _ track: RTCMediaStreamTrack,
        streamIds: [String],
        trackType: TrackType
    ) {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) is adding stream track for
            TrackId: \(track.trackId)
            TrackType: \(trackType.rawValue)
            StreamIds: \(streamIds.map(\.description))
            """,
            subsystems: .peerConnection
        )
        publishedTracks.append(trackType)
        pc.add(track, streamIds: streamIds)
    }

    func addTransceiver(
        _ track: RTCMediaStreamTrack,
        streamIds: [String],
        direction: RTCRtpTransceiverDirection = .sendOnly,
        trackType: TrackType
    ) {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) is adding transceiver for
            TrackId: \(track.trackId)
            TrackType: \(trackType.rawValue)
            StreamIds: \(streamIds.map(\.description))
            Direction: \(direction)
            """,
            subsystems: .peerConnection
        )
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
            log.debug(
                """
                PeerConnection of type:\(type.rawValue) cannot add ICE candidate
                because remoteDescription was not set.
                ICECandidate: \(iceCandidate.description)

                Candidate will be pending to add.
                """,
                subsystems: .peerConnection
            )
            pendingIceCandidates.append(iceCandidate)
            return
        }
        try await add(candidate: iceCandidate)
    }
    
    func restartIce() {
        log.debug(
            "PeerConnection of type:\(type.rawValue) is restarting ICE.",
            subsystems: .peerConnection
        )
        pc.restartIce()
    }

    func close() {
        log.debug(
            "PeerConnection of type:\(type.rawValue) was closed.",
            subsystems: .peerConnection
        )
        pc.close()
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange stateChanged: RTCSignalingState
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) didChange RTCSignalingState newState:\(stateChanged)",
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd stream: RTCMediaStream
    ) {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) didAdd stream:
            SFU: \(signalService.hostname)
            StreamId: \(stream.streamId)
            """,
            subsystems: .peerConnection
        )

        if stream.streamId.contains(WebRTCClient.Constants.screenshareTrackType) {
            screensharingStreams.append(stream)
        }
        onStreamAdded?(stream)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove stream: RTCMediaStream
    ) {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) didRemove stream:
            SFU: \(signalService.hostname)
            StreamId: \(stream.streamId)
            """,
            subsystems: .peerConnection
        )
        onStreamRemoved?(stream)
    }

    func peerConnectionShouldNegotiate(
        _ peerConnection: RTCPeerConnection
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) should negotiate.",
            subsystems: .peerConnection
        )
        onNegotiationNeeded?(self, .defaultConstraints)
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceConnectionState
    ) {
        func logMessage(_ level: LogLevel) {
            log.log(
                level,
                message: "PeerConnection of type:\(type.rawValue) didChange RTCIceConnectionState newState:\(newState)",
                subsystems: .peerConnection,
                error: nil
            )
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

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCIceGatheringState
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) didChange ICEGatheringState newState:\(newState)",
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didGenerate candidate: RTCIceCandidate
    ) {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) didGenerate ICE candidate:
            \(candidate.description)
            """,
            subsystems: .peerConnection
        )

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

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove candidates: [RTCIceCandidate]
    ) {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) didRemove ICE candidates:
            \(candidates.map(\.description))
            """,
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didOpen dataChannel: RTCDataChannel
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) didOpen dataChannel:\(dataChannel.description)",
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didFailToGatherIceCandidate event: RTCIceCandidateErrorEvent
    ) {
        let message = event.errorText.isEmpty ? "<unavailable>" : event.errorText
        log.error(
            """
            PeerConnection of type:\(type.rawValue) produced an error with code:\(event.errorCode) message:\(message)
            URL: \(event.url)
            Address: \(event.address)
            Port: \(event.port)
            """,
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChangeLocalCandidate local: RTCIceCandidate,
        remoteCandidate remote: RTCIceCandidate,
        lastReceivedMs lastDataReceivedMs: Int32,
        changeReason reason: String
    ) {
        let reason = reason.isEmpty ? "<unavailable>" : reason
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) didChangeLocalCandidate with reason:\(reason):
            local: \(local)
            remote: \(remote)
            lastDataReceivedMs: \(lastDataReceivedMs)
            """,
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChangeStandardizedIceConnectionState newState: RTCIceConnectionState
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) didChangeStandardizedIceConnectionState newState: \(newState)",
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didChange newState: RTCPeerConnectionState
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) didChangeConnectionState newState: \(newState)",
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didRemove rtpReceiver: RTCRtpReceiver
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) didRemoveRTPReceiver receiverId: \(rtpReceiver.receiverId)",
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didAdd rtpReceiver: RTCRtpReceiver,
        streams mediaStreams: [RTCMediaStream]
    ) {
        log.debug(
            """
            PeerConnection of type:\(type.rawValue) didAdd stream to receiverId: \(rtpReceiver.receiverId)
            MediaStream: \(mediaStreams.map(\.streamId))
            """,
            subsystems: .peerConnection
        )
    }

    func peerConnection(
        _ peerConnection: RTCPeerConnection,
        didStartReceivingOn transceiver: RTCRtpTransceiver
    ) {
        log.debug(
            "PeerConnection of type:\(type.rawValue) didStartReceivingOn transceiver:\(transceiver)",
            subsystems: .peerConnection
        )
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
                    log.error("Error adding ice candidate", subsystems: .peerConnection, error: error)
                    continuation.resume(throwing: error)
                } else {
                    log.debug("Added ice candidate successfully", subsystems: .peerConnection)
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

extension RTCPeerConnectionState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .new:
            return "new"
        case .connecting:
            return "connecting"
        case .connected:
            return "connected"
        case .disconnected:
            return "disconnected"
        case .failed:
            return "failed"
        case .closed:
            return "closed"
        @unknown default:
            return "unknown/default"
        }
    }
}

extension RTCSignalingState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .stable:
            return "stable"
        case .haveLocalOffer:
            return "haveLocalOffer"
        case .haveLocalPrAnswer:
            return "haveLocalPrAnswer"
        case .haveRemoteOffer:
            return "haveRemoteOffer"
        case .haveRemotePrAnswer:
            return "haveRemotePrAnswer"
        case .closed:
            return "closed"
        @unknown default:
            return "unknown/default"
        }
    }
}

extension RTCRtpTransceiverDirection: CustomStringConvertible {
    public var description: String {
        switch self {
        case .sendRecv:
            return "sendRecv"
        case .sendOnly:
            return "sendOnly"
        case .recvOnly:
            return "recvOnly"
        case .inactive:
            return "inactive"
        case .stopped:
            return "stopped"
        @unknown default:
            return "unknown/default"
        }
    }
}

extension RTCIceGatheringState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .new:
            return "new"
        case .gathering:
            return "gathering"
        case .complete:
            return "complete"
        @unknown default:
            return "unknown/default"
        }
    }
}

extension RTCSdpType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .offer:
            return "offer"
        case .prAnswer:
            return "prAnswer"
        case .answer:
            return "answer"
        case .rollback:
            return "rollback"
        @unknown default:
            return "unknown/default"
        }
    }
}
