//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension StreamRTCPeerConnection {
    /// Indicates that a remote description has been set.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct HasRemoteDescription: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "hasRemoteDescription" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    /// Indicates that the peer connection should negotiate.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    struct ShouldNegotiateEvent: RTCPeerConnectionEvent {
        var traceTag: String { "shouldNegotiate" }
    }

    /// Indicates that an ICE restart has occurred.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    struct ICERestartEvent: RTCPeerConnectionEvent {
        var traceTag: String { "ICERestart" }
    }

    /// Indicates a change in the signaling state.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct SignalingStateChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCSignalingState

        var traceTag: String { "signalingstatechange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that a media stream has been added.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct AddedStreamEvent: RTCPeerConnectionEvent, Encodable {
        let stream: RTCMediaStream

        var traceTag: String { "addedStream" }
        var traceData: AnyEncodable { .init(stream) }
    }

    /// Indicates that a media stream has been removed.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct RemovedStreamEvent: RTCPeerConnectionEvent, Encodable {
        let stream: RTCMediaStream

        var traceTag: String { "removedStream" }
        var traceData: AnyEncodable { .init(stream) }
    }

    /// Indicates that an RTP receiver has been added.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct AddedReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]

        var traceTag: String { "addedReceiver" }
        var traceData: AnyEncodable { .init(self) }
    }

    /// Indicates that an RTP receiver has been removed.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct RemovedReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver

        var traceTag: String { "removedReceiver" }
        var traceData: AnyEncodable { .init(receiver) }
    }

    /// Indicates a change in the peer connection state.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct PeerConnectionStateChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCPeerConnectionState

        var traceTag: String { "connectionstatechange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates a change in the ICE connection state.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct ICEConnectionChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCIceConnectionState

        var traceTag: String { "iceconnectionstatechange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates a change in the ICE gathering state.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct ICEGatheringChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCIceGatheringState

        var traceTag: String { "ICEGatheringStateChange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that ICE candidates have been removed.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct ICECandidatesRemovedEvent: RTCPeerConnectionEvent, Encodable {
        let candidates: [RTCIceCandidate]

        var traceTag: String { "ICECandidatesRemoved" }
        var traceData: AnyEncodable { .init(candidates) }
    }

    /// Indicates a failure in gathering an ICE candidate.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct ICECandidateFailedToGatherEvent: RTCPeerConnectionEvent, Encodable {
        let errorEvent: RTCIceCandidateErrorEvent

        var traceTag: String { "ICECandidateFailedToGather" }
        var traceData: AnyEncodable { .init(errorEvent) }
    }

    /// Indicates a change in the standardized ICE connection state.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidChangeStandardizedICEConnectionStateEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCIceConnectionState

        var traceTag: String { "didChangeStandardizedICEConnectionState" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that a data channel has been opened.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidOpenDataChannelEvent: RTCPeerConnectionEvent, Encodable {
        let dataChannel: RTCDataChannel

        var traceTag: String { "didOpenDataChannel" }
        var traceData: AnyEncodable { .init(dataChannel) }
    }

    /// Indicates a change in the connection state.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidChangeConnectionStateEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCPeerConnectionState

        var traceTag: String { "didChangeConnectionState" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that a transceiver has started receiving.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    struct DidStartReceivingOnTransceiverEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver

        var traceTag: String { "didStartReceivingOnTransceiver" }
    }

    /// Indicates that an RTP receiver has been added.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidAddReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]

        var traceTag: String { "didAddReceiver" }
        var traceData: AnyEncodable { .init(self) }
    }

    /// Indicates that an RTP receiver has been removed.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidRemoveReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver

        var traceTag: String { "didRemoveReceiver" }
        var traceData: AnyEncodable { .init(receiver) }
    }

    /// Indicates a change in the local ICE candidate.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidChangeLocalCandidateEvent: RTCPeerConnectionEvent, Encodable {
        let candidate: RTCIceCandidate

        var traceTag: String { "didChangeLocalCandidate" }
        var traceData: AnyEncodable { .init(candidate) }
    }

    /// Indicates a change in the remote ICE candidate.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidChangeRemoteCandidateEvent: RTCPeerConnectionEvent, Encodable {
        let candidate: RTCIceCandidate

        var traceTag: String { "didChangeRemoteCandidate" }
        var traceData: AnyEncodable { .init(candidate) }
    }

    /// Indicates a change in a transceiver.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    struct DidChangeEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver

        var traceTag: String { "didChange" }
    }

    /// Indicates that an ICE candidate has been generated.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidGenerateICECandidateEvent: RTCPeerConnectionEvent, Encodable {
        let candidate: RTCIceCandidate

        var traceTag: String { "didGenerateICECandidate" }
        var traceData: AnyEncodable { .init(candidate) }
    }

    /// Indicates that ICE candidates have been removed.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidRemoveICECandidatesEvent: RTCPeerConnectionEvent, Encodable {
        let candidates: [RTCIceCandidate]

        var traceTag: String { "didRemoveICECandidates" }
        var traceData: AnyEncodable { .init(candidates) }
    }

    /// Indicates a change in both local and remote ICE candidates.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct DidChangeLocalCandidateWithRemoteEvent: RTCPeerConnectionEvent, Encodable {
        let localCandidate: RTCIceCandidate
        let remoteCandidate: RTCIceCandidate
        let lastDataReceivedMs: Int32
        let reason: String

        var traceTag: String { "didChangeLocalCandidateWithRemote" }
        var traceData: AnyEncodable { .init(self) }
    }

    /// Indicates that the peer connection has been created.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct CreatedEvent: RTCPeerConnectionEvent, Encodable {
        var configuration: RTCConfiguration
        var hostname: String

        var traceTag: String { "create" }
        var traceData: AnyEncodable {
            var data: [String: AnyEncodable] = configuration.toDictionary()
            data["url"] = .init(hostname)
            return .init(data)
        }
    }

    /// Indicates that an offer has been created.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct CreateOfferEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "createOffer" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    /// Indicates that an answer has been created.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct CreateAnswerEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "createAnswer" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    /// Indicates that the local description has been set.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct SetLocalDescriptionEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "setLocalDescription" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    /// Indicates that the remote description has been set.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    /// - traceData: The encoded data associated with this event.
    struct SetRemoteDescriptionEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "setRemoteDescription" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    /// Indicates that the peer connection has been closed.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    struct CloseEvent: RTCPeerConnectionEvent, Encodable {
        var traceTag: String { "close" }
    }

    /// Indicates that the ICE restart process has been initiated.
    ///
    /// - traceTag: A unique string identifier used in tracing.
    struct RestartICEEvent: RTCPeerConnectionEvent, Encodable {
        var traceTag: String { "restartICE" }
    }
}
