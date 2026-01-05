//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC
import SwiftProtobuf

/// Represents a trace event for WebRTC-related actions and state changes.
///
/// This struct provides a unified way to log, encode, and analyze significant
/// events and data points in the WebRTC pipeline. Each trace contains a tag
/// describing the event, an optional identifier (such as a peer connection ID),
/// associated data (type-erased), and a timestamp.
///
/// Events can be created for various system components such as peer connections,
/// SFU adapters, audio sessions, and network status.
struct WebRTCTrace: Sendable, Encodable, Equatable {
    /// The name/tag of the event (e.g. `createOffer`, `getstats`).
    var tag: String

    /// The identifier for the peer connection or subsystem. `nil` for events
    /// not tied to a specific peer connection.
    var id: String?

    /// Additional event data, encoded in a type-erased fashion.
    var data: AnyEncodable?

    /// The timestamp of the event in milliseconds since 1970-01-01T00:00:00Z.
    var timestamp: Int64

    /// Private initializer for creating a trace event.
    ///
    /// - Parameters:
    ///   - id: The identifier for the event source (optional).
    ///   - tag: The string tag for the event.
    ///   - data: The event's associated data, type-erased (optional).
    ///   - timestamp: The event's timestamp (defaults to now).
    init(
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

    /// Encodes the trace as an array for compactness:
    /// `[tag, id, data, timestamp]`.
    ///
    /// - Parameter encoder: The encoder to write data to.
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(tag)
        try container.encode(id)
        try container.encode(data)
        try container.encode(timestamp)
    }
}

extension WebRTCTrace {
    /// Creates a trace event from a peer connection event.
    ///
    /// - Parameters:
    ///   - peerType: The type of the peer connection (publisher, subscriber).
    ///   - event: The peer connection event to trace.
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

    /// Creates a trace event from a peer connection statistics report.
    ///
    /// - Parameters:
    ///   - peerType: The type of the peer connection (publisher, subscriber).
    ///   - statsReport: The statistics report to attach.
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
    /// Creates a trace event from an SFU adapter event.
    ///
    /// - Parameter event: The SFUAdapterEvent to trace.
    init(
        event: SFUAdapterEvent
    ) {
        self.init(
            id: "sfu",
            tag: event.traceTag,
            data: event.traceData
        )
    }

    /// Creates a trace event from a protobuf message.
    ///
    /// - Parameters:
    ///   - tag: The name of the event.
    ///   - event: The protocol buffer message, encoded as JSON.
    init(
        tag: String,
        event: SelectiveEncodable
    ) {
        self.init(
            id: "sfu",
            tag: tag,
            data: .init(event)
        )
    }
}

extension WebRTCTrace {
    /// Creates a trace for a successful getUserMedia operation, including
    /// the current audio session settings.
    ///
    /// - Parameters:
    ///   - callSettings: The active call settings.
    ///   - audioSession: The audio session state.
    init(
        audioSession: CallAudioSession.TraceRepresentation
    ) {
        self.init(
            id: nil,
            tag: "navigator.mediaDevices.getUserMediaOnSuccess",
            data: .init(audioSession)
        )
    }
}

extension WebRTCTrace {
    /// Creates a trace event for a change in network connectivity status.
    ///
    /// The data field is set to `"online"` when available, `"offline"`
    /// otherwise.
    ///
    /// - Parameter status: The current internet connection status.
    init(
        status: InternetConnectionStatus
    ) {
        let tag = {
            switch status {
            case .available:
                return "network.state.online"
            case .unavailable, .unknown:
                return "network.state.offline"
            }
        }()
        self.init(
            id: nil,
            tag: tag,
            data: nil
        )
    }
}

extension WebRTCTrace {
    enum CallKitAction: String {
        case didReset
        case didActivateAudioSession
        case didDeactivateAudioSession
        case performAnswerCall
        case performEndCall
        case performRejectCall
        case performSetMutedCall
    }

    init(
        _ action: CallKitAction
    ) {
        self.init(
            id: nil,
            tag: "callKit.\(action.rawValue)",
            data: nil
        )
    }
}

extension WebRTCTrace {

    init(
        applicationState: ApplicationState
    ) {
        self.init(
            id: nil,
            tag: "application.state.\(applicationState.rawValue)",
            data: nil
        )
    }
}

extension WebRTCTrace {

    init(
        thermalState: ProcessInfo.ThermalState
    ) {
        self.init(
            id: nil,
            tag: "device.thermal.state.\(thermalState)",
            data: nil
        )
    }
}

extension WebRTCTrace {
    init(
        _ battery: BatteryStore
    ) {
        self.init(
            id: nil,
            tag: "device.battery.\(battery.state.state)",
            data: .init(battery)
        )
    }
}
