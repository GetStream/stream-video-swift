//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

/// A protocol describing a traceable event emitted by an RTCPeerConnection.
///
/// Conforming types provide a trace tag and optional associated trace data,
/// used for debugging, logging, or analytics. Events represent state changes,
/// transitions, or observations in the WebRTC peer connection lifecycle.
protocol RTCPeerConnectionEvent {
    /// A unique string identifier for the type of event.
    ///
    /// Used to categorize and distinguish events during trace logging.
    var traceTag: String { get }

    /// Encoded metadata or payload associated with the event.
    ///
    /// Defaults to an empty string if not overridden by the conforming type.
    var traceData: AnyEncodable { get }
}

extension RTCPeerConnectionEvent {
    var traceData: AnyEncodable { .init("") }
}
