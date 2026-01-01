//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Factory for creating WebRTC join requests.
struct WebRTCJoinRequestFactory {
    /// Represents different types of connection for join requests.
    enum ConnectionType {
        case `default`
        case fastReconnect
        case migration(fromHostname: String)
        case rejoin(fromSessionID: String)

        /// Indicates if the connection type is a fast reconnect.
        var isFastReconnect: Bool {
            switch self {
            case .fastReconnect:
                true
            default:
                false
            }
        }
    }

    var capabilities: [Stream_Video_Sfu_Models_ClientCapability]

    /// Builds a join request for WebRTC.
    /// - Parameters:
    ///   - connectionType: The type of connection for the join request.
    ///   - coordinator: The WebRTC coordinator.
    ///   - publisherSdp: The publisher's SDP.
    ///   - subscriberSdp: The subscriber's SDP.
    ///   - reconnectAttempt: The number of reconnect attempts.
    ///   - publisher: The RTC peer connection coordinator for publishing.
    ///   - file: The file where the method is called.
    ///   - function: The function where the method is called.
    ///   - line: The line number where the method is called.
    /// - Returns: A join request for the SFU.
    func buildRequest(
        with connectionType: ConnectionType,
        coordinator: WebRTCCoordinator,
        publisherSdp: String,
        subscriberSdp: String,
        reconnectAttempt: UInt32,
        publisher: RTCPeerConnectionCoordinator?,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) async -> Stream_Video_Sfu_Event_JoinRequest {
        var result = Stream_Video_Sfu_Event_JoinRequest()
        result.clientDetails = SystemEnvironment.clientDetails
        result.sessionID = await coordinator.stateAdapter.sessionID
        result.publisherSdp = publisherSdp
        result.subscriberSdp = subscriberSdp
        result.fastReconnect = connectionType.isFastReconnect
        result.token = await coordinator.stateAdapter.token
        result.preferredPublishOptions = await buildPreferredPublishOptions(
            coordinator: coordinator,
            publisherSdp: publisherSdp
        )
        result.capabilities = capabilities
        result.source = .webrtcUnspecified
        result.unifiedSessionID = coordinator.stateAdapter.unifiedSessionId

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

    /// Builds reconnect details for the join request.
    /// - Parameters:
    ///   - connectionType: The type of connection for the join request.
    ///   - coordinator: The WebRTC coordinator.
    ///   - reconnectAttempt: The number of reconnect attempts.
    ///   - publisher: The RTC peer connection coordinator for publishing.
    ///   - file: The file where the method is called.
    ///   - function: The function where the method is called.
    ///   - line: The line number where the method is called.
    /// - Returns: Reconnect details for the join request.
    func buildReconnectDetails(
        for connectionType: ConnectionType,
        coordinator: WebRTCCoordinator,
        reconnectAttempt: UInt32,
        publisher: RTCPeerConnectionCoordinator?,
        file: StaticString = #fileID,
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
                collectionType: .allAvailable,
                file: file,
                function: function,
                line: line
            )
            result.subscriptions = await buildSubscriptionDetails(
                nil,
                sessionID: coordinator.stateAdapter.sessionID,
                participants: Array(coordinator.stateAdapter.participants.values),
                incomingVideoQualitySettings: coordinator
                    .stateAdapter
                    .incomingVideoQualitySettings,
                file: file,
                function: function,
                line: line
            )
            result.strategy = .fast
            result.reconnectAttempt = reconnectAttempt

        case let .migration(fromHostname):
            result.announcedTracks = buildAnnouncedTracks(
                publisher,
                collectionType: .lastPublishOptions,
                file: file,
                function: function,
                line: line
            )
            result.fromSfuID = fromHostname
            result.subscriptions = await buildSubscriptionDetails(
                nil,
                sessionID: coordinator.stateAdapter.sessionID,
                participants: Array(coordinator.stateAdapter.participants.values),
                incomingVideoQualitySettings: coordinator
                    .stateAdapter
                    .incomingVideoQualitySettings,
                file: file,
                function: function,
                line: line
            )
            result.strategy = .migrate
            result.reconnectAttempt = reconnectAttempt

        case let .rejoin(fromSessionID):
            result.announcedTracks = buildAnnouncedTracks(
                publisher,
                collectionType: .lastPublishOptions,
                file: file,
                function: function,
                line: line
            )
            result.subscriptions = await buildSubscriptionDetails(
                fromSessionID,
                sessionID: coordinator.stateAdapter.sessionID,
                participants: Array(coordinator.stateAdapter.participants.values),
                incomingVideoQualitySettings: coordinator
                    .stateAdapter
                    .incomingVideoQualitySettings,
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

    /// Builds announced tracks for the join request.
    /// - Parameters:
    ///   - publisher: The RTC peer connection coordinator for publishing.
    ///   - file: The file where the method is called.
    ///   - function: The function where the method is called.
    ///   - line: The line number where the method is called.
    /// - Returns: An array of announced tracks.
    func buildAnnouncedTracks(
        _ publisher: RTCPeerConnectionCoordinator?,
        collectionType: RTCPeerConnectionTrackInfoCollectionType,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) -> [Stream_Video_Sfu_Models_TrackInfo] {
        var result = [Stream_Video_Sfu_Models_TrackInfo]()

        guard let publisher else {
            return result
        }

        result.append(contentsOf: publisher.trackInfo(for: .audio, collectionType: collectionType))
        result.append(contentsOf: publisher.trackInfo(for: .video, collectionType: collectionType))
        result.append(contentsOf: publisher.trackInfo(for: .screenshare, collectionType: collectionType))

        return result
    }

    /// Builds subscription details for the join request.
    /// - Parameters:
    ///   - previousSessionID: The previous session ID, if any.
    ///   - coordinator: The WebRTC coordinator.
    ///   - incomingVideoQualitySettings: The `IncomingVideoQualitySettings` for
    ///   the current session.
    ///   - file: The file where the method is called.
    ///   - function: The function where the method is called.
    ///   - line: The line number where the method is called.
    /// - Returns: An array of track subscription details.
    func buildSubscriptionDetails(
        _ previousSessionID: String?,
        sessionID: String,
        participants: [CallParticipant],
        incomingVideoQualitySettings: IncomingVideoQualitySettings,
        file: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line
    ) -> [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] {
        participants
            .filter { $0.id != sessionID && $0.id != previousSessionID }
            .flatMap { $0.trackSubscriptionDetails(incomingVideoQualitySettings: incomingVideoQualitySettings) }
    }

    func buildPreferredPublishOptions(
        coordinator: WebRTCCoordinator,
        publisherSdp: String
    ) async -> [Stream_Video_Sfu_Models_PublishOption] {
        let sdpParser = SDPParser()
        let rtmapVisitor = RTPMapVisitor()
        sdpParser.registerVisitor(rtmapVisitor)
        await sdpParser.parse(sdp: publisherSdp)

        return await coordinator
            .stateAdapter
            .publishOptions
            .source
            .map {
                var publishOption = $0
                publishOption.codec.payloadType = UInt32(rtmapVisitor.payloadType(for: $0.codec.name) ?? 0)
                return publishOption
            }
    }
}
