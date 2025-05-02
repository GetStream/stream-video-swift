//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import SwiftProtobuf

struct WebRTCTrace: Sendable, Encodable {
    // the name of the event
    // e.g. `createOffer`, `createOfferOnSuccess`, `createOfferOnFailure`
    var tag: String

    // Peer Connection identifier (eg. Publisher 1, Subscriber 2)
    // null for non-PC events
    var id: String?

    // the data to provide
    var data: AnyEncodable?

    // the timestamp of the event, usually `Date.now()`
    var timestamp: Int64

    private init(
        id: String?,
        tag: String,
        data: AnyEncodable?,
        timestamp: Int64 = Date().millisecondsSince1970
    ) {
        self.id = id
        self.tag = tag
        self.data = data
        self.timestamp = timestamp
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(tag)
        try container.encode(id)
        try container.encode(data)
        try container.encode(timestamp)
    }
}

extension WebRTCTrace {

    init(
        peerType: PeerConnectionType,
        event: RTCPeerConnectionEvent
    ) {
        self.init(
            id: peerType.rawValue,
            tag: event.traceTag,
            data: event.traceData
        )
    }

    init(
        peerType: PeerConnectionType,
        statsReport: MutableRTCStatisticsReport
    ) {
        self.init(
            id: peerType.rawValue,
            tag: "getstats",
            data: .init(statsReport)
        )
    }
}

extension WebRTCTrace {
    init(
        event: SFUAdapterEvent
    ) {
        self.init(
            id: nil,
            tag: event.traceTag,
            data: event.traceData
        )
    }

    init(
        tag: String,
        event: SwiftProtobuf.Message
    ) {
        self.init(
            id: nil,
            tag: tag,
            data: .init(try? event.jsonString())
        )
    }
}

extension WebRTCTrace {
    init(
        callSettings: CallSettings,
        audioSession: StreamAudioSession
    ) {
        self.init(
            id: nil,
            tag: "navigator.mediaDevices.getUserMediaOnSuccess",
            data: .init(audioSession)
        )
    }
}

extension WebRTCTrace {
    init(
        status: InternetConnectionStatus
    ) {
        let data = {
            switch status {
            case .available:
                return "online"
            case .unavailable, .unknown:
                return "offline"
            }
        }()
        self.init(
            id: nil,
            tag: "network.changed",
            data: .init(data)
        )
    }
}
