//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

/// A simple protocol describing an event created from an RTCPeerConnection.
protocol RTCPeerConnectionEvent {
    var traceTag: String { get }

    var traceData: AnyEncodable { get }
}

extension RTCPeerConnectionEvent {
    var traceData: AnyEncodable { .init("") }
}
