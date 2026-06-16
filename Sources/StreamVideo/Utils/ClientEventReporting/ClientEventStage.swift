//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Identifies a join-lifecycle stage reported through ``ClientEventReporting``.
///
/// The raw values are sent verbatim in the ``ClientEvent/stage`` field and are
/// matched by the backend to correlate the `initiated` / `completed` pair that
/// share the same `stage_id`.
enum ClientEventStage: String, Sendable {
    /// Fired immediately when `Call.join()` is requested (and on every full
    /// rejoin / migration, which are treated as new join attempts).
    case joinInitiated = "JoinInitiated"
    /// The SFU WebSocket connection becoming ready for authentication.
    case coordinatorWS = "CoordinatorWS"
    /// The media permission prompt/check point for requested local devices.
    case mediaDevicePermission = "MediaDevicePermission"
    /// The coordinator `JoinCall` REST request.
    case coordinatorJoin = "CoordinatorJoin"
    /// The SFU signaling WebSocket join handshake.
    case wsJoin = "WSJoin"
    /// A publisher or subscriber peer-connection connect attempt.
    case peerConnectionConnect = "PeerConnectionConnect"
    /// The first remote video frame signal observed by the client.
    case firstVideoFrame = "FirstVideoFrame"
    /// The first remote audio frame signal observed by the client.
    case firstAudioFrame = "FirstAudioFrame"
}

/// Whether an event marks the start or the resolution of a stage attempt.
enum ClientEventType: String, Sendable {
    /// Emitted when the client begins the stage attempt.
    case initiated
    /// Emitted when the stage attempt resolves (success or failure).
    case completed
}

/// The resolution of a `completed` event.
enum ClientEventOutcome: String, Sendable {
    /// The stage attempt resolved cleanly (possibly after in-stage retries).
    case success
    /// The stage attempt exhausted its retries.
    case failure
}

/// Permission status values reported on
/// ``ClientEventStage/mediaDevicePermission``.
enum ClientEventPermissionStatus: String, Sendable, Equatable {
    /// The SDK started a system permission request.
    case initiated = "INITIATED"
    /// The permission is denied or unavailable.
    case failed = "FAILED"
    /// The permission is already granted.
    case granted = "GRANTED"
    /// The permission was not requested for this attempt.
    case notInitiated = "NOT_INITIATED"
}

/// Which peer connection a ``ClientEventStage/peerConnectionConnect`` event
/// reports on. The raw values follow the backend contract (`publish` /
/// `subscribe`) which differs from the internal ``PeerConnectionType``.
enum ClientEventPeerConnection: String, Sendable {
    case publish
    case subscribe

    /// Maps the internal peer-connection type to its wire representation.
    init(_ peerConnectionType: PeerConnectionType) {
        switch peerConnectionType {
        case .publisher:
            self = .publish
        case .subscriber:
            self = .subscribe
        }
    }
}

/// Terminal ICE state attached to a ``ClientEventStage/peerConnectionConnect``
/// failure event.
enum ClientEventICEState: String, Sendable {
    case connected = "CONNECTED"
    case failed = "FAILED"
    case notConnected = "NOT_CONNECTED"
}

/// Standard client-side failure codes valid for any stage's
/// `retry_failure_code` field.
enum ClientEventFailureCode: String, Sendable {
    /// SDK was retrying and the client left the call.
    case clientAborted = "CLIENT_ABORTED"
    /// No response within the client timeout.
    case requestTimeout = "REQUEST_TIMEOUT"
    /// Device reports no network.
    case networkOffline = "NETWORK_OFFLINE"
    /// ICE connectivity checks failed (`PeerConnectionConnect` only).
    case iceConnectivityFailed = "ICE_CONNECTIVITY_FAILED"
    /// DTLS handshake failed.
    case dtlsConnectivityFailed = "DTLS_CONNECTIVITY_FAILED"
    /// SDK was trying to join but received a backend leave during that time.
    case backendLeave = "BACKEND_LEAVE"
}
