//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import SwiftProtobuf

//enum PeerConnectionType: String {
//    case subscriber
//    case publisher
//}

class PeerConnection: NSObject, @unchecked Sendable {

    let pc: RTCPeerConnection
    private let eventDecoder: WebRTCEventDecoder
    var sfuAdapter: SFUAdapter
    private let sessionId: String
    let type: PeerConnectionType
    private let videoOptions: VideoOptions
    private(set) var transceiver: RTCRtpTransceiver?
    private(set) var transceiverScreenshare: RTCRtpTransceiver?
    private var publishedTracks = [TrackType]()
    private var screensharingStreams = [RTCMediaStream]()

    private let queue = UnfairQueue()
    private let iceAdapter: ICEAdapter
    private let disposableBag = DisposableBag()

    var onNegotiationNeeded: ((PeerConnection, RTCMediaConstraints?) -> Void)?
    var onDisconnect: ((PeerConnection) -> Void)?
    var onConnected: ((PeerConnection) -> Void)?
    var onStreamAdded: ((RTCMediaStream) -> Void)?
    var onStreamRemoved: ((RTCMediaStream) -> Void)?

    var paused = false
    
    var connectionState: RTCPeerConnectionState {
        pc.connectionState
    }

    private let subsystem: LogSubsystem

    init(
        sessionId: String,
        pc: RTCPeerConnection,
        type: PeerConnectionType,
        sfuAdapter: SFUAdapter,
        videoOptions: VideoOptions
    ) {
        self.sessionId = sessionId
        self.pc = pc
        self.sfuAdapter = sfuAdapter
        self.type = type
        self.videoOptions = videoOptions
        subsystem = type == .publisher ? .peerConnection_publisher : .peerConnection_subscriber
        eventDecoder = WebRTCEventDecoder()
        self.iceAdapter = ICEAdapter(
            sessionID: sessionId,
            peerType: type,
            peerConnection: pc,
            sfuAdapter: sfuAdapter
        )
        super.init()
//        self.pc.delegate = self

        pc
            .publisher(eventType: RTCPeerConnection.AddedStreamEvent.self)
            .sink { [weak self] event in
                guard let self else { return }
                if event.stream.streamId.contains(WebRTCClient.Constants.screenshareTrackType) {
                    screensharingStreams.append(event.stream)
                }
                onStreamAdded?(event.stream)
            }
            .store(in: disposableBag)
        pc
            .publisher(eventType: RTCPeerConnection.RemovedStreamEvent.self)
            .sink { [weak self] event in self?.onStreamRemoved?(event.stream) }
            .store(in: disposableBag)

        pc
            .publisher(eventType: RTCPeerConnection.ShouldNegotiateEvent.self)
            .sink { [weak self] event in
                guard let self else { return }
                onNegotiationNeeded?(self, .defaultConstraints)
            }
            .store(in: disposableBag)

        pc
            .publisher(eventType: RTCPeerConnection.DidChangeConnectionStateEvent.self)
            .filter { $0.state == .disconnected }
            .map { _ in () }
            .sink { [weak self] in
                guard let self else { return }
                onDisconnect?(self)
            }
            .store(in: disposableBag)

        pc
            .publisher(eventType: RTCPeerConnection.DidChangeConnectionStateEvent.self)
            .filter { $0.state == .connected }
            .map { _ in () }
            .sink { [weak self] in
                guard let self else { return }
                onConnected?(self)
            }
            .store(in: disposableBag)

        if type == .subscriber {
            sfuAdapter
                .publisher(eventType: Stream_Video_Sfu_Event_SubscriberOffer.self)
                .log(.debug, subsystems: subsystem)
                .sinkTask { [weak self] event in
                    guard let self else { return }
                    do {
                        let offerSdp = event.sdp
                        try await setRemoteDescription(offerSdp, type: .offer)

                        let answer = try await createAnswer()
                        try await setLocalDescription(answer)

                        try await sfuAdapter.sendAnswer(
                            sessionDescription: answer.sdp,
                            peerType: .subscriber,
                            for: sessionId
                        )
                    } catch {
                        log.error(
                            "Error handling offer event",
                            subsystems: subsystem,
                            error: error
                        )
                    }
                }
                .store(in: disposableBag)
        }

        log.debug(
            """
            PeerConnection of type:\(type.rawValue) was created.
            SignalService:\(sfuAdapter.hostname)
            SessionId:\(sessionId)
            PreferredFps: \(videoOptions.preferredFps)
            SupportedCodecs: \(videoOptions.supportedCodecs.map(\.quality))
            PreferredDimensions: \(videoOptions.preferredDimensions)
            PreferredFormat: \(videoOptions.preferredFormat?.description ?? "nil")
            """,
            subsystems: subsystem
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
        try await pc.createOffer(constraints: constraints)
    }

    func createAnswer() async throws -> RTCSessionDescription {
        try await pc.answer(for: .defaultConstraints)
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
        try await pc.setLocalDescription(sdp)
    }

    func setRemoteDescription(
        _ sdp: String,
        type: RTCSdpType
    ) async throws {
        try await pc.setRemoteDescription(.init(type: type, sdp: sdp))
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
            subsystems: subsystem
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
            subsystems: subsystem
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

    func restartIce() {
        log.debug(
            "PeerConnection of type:\(type.rawValue) is restarting ICE.",
            subsystems: subsystem
        )
        pc.restartIce()
    }

    func close() {
        log.debug(
            "PeerConnection of type:\(type.rawValue) was closed.",
            subsystems: subsystem
        )
        pc.close()
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
}

extension RTCIceCandidate {

    func toIceCandidate() -> ICECandidate {
        .init(from: self)
    }
}

extension RTCVideoCodecInfo {

    func toSfuCodec() -> Stream_Video_Sfu_Models_Codec {
        var codec = Stream_Video_Sfu_Models_Codec()
        codec.name = name
        return codec
    }
}
