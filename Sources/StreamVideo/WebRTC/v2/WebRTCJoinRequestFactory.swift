//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

struct WebRTCJoinRequestFactory {
    enum ConnectionType {
        case `default`
        case fastReconnect
        case migration(fromHostname: String)
        case rejoin(fromSessionID: String)

        var isFastReconnect: Bool {
            switch self {
            case .fastReconnect:
                return true
            default:
                return false
            }
        }
    }

    func buildRequest(
        with connectionType: ConnectionType,
        coordinator: WebRTCCoordinator,
        subscriberSdp: String,
        reconnectAttempt: UInt32,
        publisher: RTCPeerConnectionCoordinator?,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async -> Stream_Video_Sfu_Event_JoinRequest {
        var result = Stream_Video_Sfu_Event_JoinRequest()
        result.clientDetails = SystemEnvironment.clientDetails
        result.sessionID = await coordinator.stateAdapter.sessionID
        result.subscriberSdp = subscriberSdp
        result.fastReconnect = connectionType.isFastReconnect
        result.token = await coordinator.stateAdapter.token
        if let reconnectDetails = await buildReconnectDetails(
            for: connectionType,
            coordinator: coordinator,
            reconnectAttempt: reconnectAttempt,
            publisher: publisher,
            file: file,
            function: function,
            line: line
        ) {
            result.reconnectDetails = reconnectDetails
        }

        return result
    }

    func buildReconnectDetails(
        for connectionType: ConnectionType,
        coordinator: WebRTCCoordinator,
        reconnectAttempt: UInt32,
        publisher: RTCPeerConnectionCoordinator?,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async -> Stream_Video_Sfu_Event_ReconnectDetails? {
        var result = Stream_Video_Sfu_Event_ReconnectDetails()

        switch connectionType {
        case .default:
            break

        case .fastReconnect:
            result.announcedTracks = buildAnnouncedTracks(
                publisher,
                videoOptions: await coordinator.stateAdapter.videoOptions,
                file: file,
                function: function,
                line: line
            )
            result.subscriptions = await buildSubscriptionDetails(
                nil,
                coordinator: coordinator,
                file: file,
                function: function,
                line: line
            )
            result.strategy = .fast
            result.reconnectAttempt = reconnectAttempt

        case let .migration(fromHostname):
            result.announcedTracks = buildAnnouncedTracks(
                publisher,
                videoOptions: await coordinator.stateAdapter.videoOptions,
                file: file,
                function: function,
                line: line
            )
            result.fromSfuID = fromHostname
            result.subscriptions = await buildSubscriptionDetails(
                nil,
                coordinator: coordinator,
                file: file,
                function: function,
                line: line
            )
            result.strategy = .migrate
            result.reconnectAttempt = reconnectAttempt

        case let .rejoin(fromSessionID):
            result.announcedTracks = buildAnnouncedTracks(
                publisher,
                videoOptions: await coordinator.stateAdapter.videoOptions,
                file: file,
                function: function,
                line: line
            )
            result.subscriptions = await buildSubscriptionDetails(
                fromSessionID,
                coordinator: coordinator,
                file: file,
                function: function,
                line: line
            )
            result.strategy = .rejoin
            result.previousSessionID = fromSessionID
            result.reconnectAttempt = reconnectAttempt
        }

        return result
    }

    func buildAnnouncedTracks(
        _ publisher: RTCPeerConnectionCoordinator?,
        videoOptions: VideoOptions,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        var result = [Stream_Video_Sfu_Models_TrackInfo]()

        if let mid = publisher?.mid(for: .audio) {
            var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
            trackInfo.trackID = publisher?.localTrack(of: .audio)?.trackId ?? ""
            trackInfo.mid = mid
            trackInfo.trackType = .audio
            trackInfo.muted = publisher?.localTrack(of: .audio)?.isEnabled != true
            result.append(trackInfo)
        }

        if let mid = publisher?.mid(for: .video) {
            var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
            trackInfo.trackID = publisher?.localTrack(of: .video)?.trackId ?? ""
            trackInfo.layers = videoOptions
                .supportedCodecs
                .map { Stream_Video_Sfu_Models_VideoLayer($0) }
            trackInfo.mid = mid
            trackInfo.trackType = .video
            trackInfo.muted = publisher?.localTrack(of: .video)?.isEnabled != true
            result.append(trackInfo)
        }
        
        if let mid = publisher?.mid(for: .screenshare) {
            var trackInfo = Stream_Video_Sfu_Models_TrackInfo()
            trackInfo.trackID = publisher?.localTrack(of: .screenshare)?.trackId ?? ""
            trackInfo.layers = [VideoCodec.screenshare]
                .map { Stream_Video_Sfu_Models_VideoLayer($0, fps: 15) }
            trackInfo.mid = mid
            trackInfo.trackType = .screenShare
            trackInfo.muted = publisher?.localTrack(of: .screenshare)?.isEnabled != true
            result.append(trackInfo)
        }

        return result
    }

    func buildSubscriptionDetails(
        _ previousSessionID: String?,
        coordinator: WebRTCCoordinator,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async -> [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] {
        let sessionID = await coordinator.stateAdapter.sessionID
        return Array(await coordinator.stateAdapter.participants.values)
            .filter { $0.id != sessionID && $0.id != previousSessionID }
            .flatMap(\.trackSubscriptionDetails)
    }
}

extension Stream_Video_Sfu_Models_VideoLayer {
    
    init(
        _ codec: VideoCodec,
        fps: UInt32 = 30
    ) {
        bitrate = UInt32(codec.maxBitrate)
        rid = codec.quality
        var dimension = Stream_Video_Sfu_Models_VideoDimension()
        dimension.height = UInt32(codec.dimensions.height)
        dimension.width = UInt32(codec.dimensions.width)
        videoDimension = dimension
        quality = codec.sfuQuality
        self.fps = fps
    }
}

extension CallParticipant {

    var trackSubscriptionDetails: [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] {
        var result = [Stream_Video_Sfu_Signal_TrackSubscriptionDetails]()
        if hasVideo {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    size: trackSize,
                    type: .video
                )
            )
        }

        if hasAudio {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    type: .audio
                )
            )
        }

        if isScreensharing {
            result.append(
                .init(
                    for: userId,
                    sessionId: sessionId,
                    type: .screenShare
                )
            )
        }

        return result
    }
}

extension Stream_Video_Sfu_Signal_TrackSubscriptionDetails {
    init(
        for userId: String,
        sessionId: String,
        size: CGSize? = nil,
        type: Stream_Video_Sfu_Models_TrackType
    ) {
        userID = userId
        dimension = size.map { Stream_Video_Sfu_Models_VideoDimension($0) } ?? Stream_Video_Sfu_Models_VideoDimension()
        sessionID = sessionId
        trackType = type
    }
}

extension Stream_Video_Sfu_Models_VideoDimension {
    init(_ size: CGSize) {
        height = UInt32(size.height)
        width = UInt32(size.width)
    }
}
