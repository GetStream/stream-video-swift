//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension StreamRTCPeerConnection {
    /// Indicates that a remote description has been set.
    struct HasRemoteDescription: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "hasRemoteDescription" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    /// Indicates that the peer connection should negotiate.
    struct ShouldNegotiateEvent: RTCPeerConnectionEvent {
        var traceTag: String { "shouldNegotiate" }
    }

    /// Indicates that an ICE restart has occurred.
    struct ICERestartEvent: RTCPeerConnectionEvent {
        var traceTag: String { "ICERestart" }
    }

    /// Indicates a change in the signaling state.
    struct SignalingStateChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCSignalingState

        var traceTag: String { "signalingstatechange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that a media stream has been added.
    struct AddedStreamEvent: RTCPeerConnectionEvent, Encodable {
        let stream: RTCMediaStream

        var traceTag: String { "addedStream" }
        var traceData: AnyEncodable { .init(stream) }
    }

    /// Indicates that a media stream has been removed.
    struct RemovedStreamEvent: RTCPeerConnectionEvent, Encodable {
        let stream: RTCMediaStream

        var traceTag: String { "removedStream" }
        var traceData: AnyEncodable { .init(stream) }
    }

    /// Indicates that an RTP receiver has been added.
    struct AddedReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]

        var traceTag: String { "addedReceiver" }
        var traceData: AnyEncodable { .init(self) }
    }

    /// Indicates that an RTP receiver has been removed.
    struct RemovedReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver

        var traceTag: String { "removedReceiver" }
        var traceData: AnyEncodable { .init(receiver) }
    }

    /// Indicates a change in the peer connection state.
    struct PeerConnectionStateChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCPeerConnectionState

        var traceTag: String { "connectionstatechange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates a change in the ICE connection state.
    struct ICEConnectionChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCIceConnectionState

        var traceTag: String { "iceconnectionstatechange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates a change in the ICE gathering state.
    struct ICEGatheringChangedEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCIceGatheringState

        var traceTag: String { "ICEGatheringStateChange" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that ICE candidates have been removed.
    struct ICECandidatesRemovedEvent: RTCPeerConnectionEvent, Encodable {
        let candidates: [RTCIceCandidate]

        var traceTag: String { "ICECandidatesRemoved" }
        var traceData: AnyEncodable { .init(candidates) }
    }

    /// Indicates a failure in gathering an ICE candidate.
    struct ICECandidateFailedToGatherEvent: RTCPeerConnectionEvent, Encodable {
        let errorEvent: RTCIceCandidateErrorEvent

        var traceTag: String { "ICECandidateFailedToGather" }
        var traceData: AnyEncodable { .init(errorEvent) }
    }

    /// Indicates a change in the standardized ICE connection state.
    struct DidChangeStandardizedICEConnectionStateEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCIceConnectionState

        var traceTag: String { "didChangeStandardizedICEConnectionState" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that a data channel has been opened.
    struct DidOpenDataChannelEvent: RTCPeerConnectionEvent, Encodable {
        let dataChannel: RTCDataChannel

        var traceTag: String { "didOpenDataChannel" }
        var traceData: AnyEncodable { .init(dataChannel) }
    }

    /// Indicates a change in the connection state.
    struct DidChangeConnectionStateEvent: RTCPeerConnectionEvent, Encodable {
        let state: RTCPeerConnectionState

        var traceTag: String { "didChangeConnectionState" }
        var traceData: AnyEncodable { .init(state.description) }
    }

    /// Indicates that a transceiver has started receiving.
    struct DidStartReceivingOnTransceiverEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver

        var traceTag: String { "didStartReceivingOnTransceiver" }
    }

    /// Indicates that an RTP receiver has been added.
    struct DidAddReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]

        var traceTag: String { "didAddReceiver" }
        var traceData: AnyEncodable { .init(self) }
    }

    /// Indicates that an RTP receiver has been removed.
    struct DidRemoveReceiverEvent: RTCPeerConnectionEvent, Encodable {
        let receiver: RTCRtpReceiver

        var traceTag: String { "didRemoveReceiver" }
        var traceData: AnyEncodable { .init(receiver) }
    }

    /// Indicates a change in the local ICE candidate.
    struct DidChangeLocalCandidateEvent: RTCPeerConnectionEvent, Encodable {
        let candidate: RTCIceCandidate

        var traceTag: String { "didChangeLocalCandidate" }
        var traceData: AnyEncodable { .init(candidate) }
    }

    /// Indicates a change in the remote ICE candidate.
    struct DidChangeRemoteCandidateEvent: RTCPeerConnectionEvent, Encodable {
        let candidate: RTCIceCandidate

        var traceTag: String { "didChangeRemoteCandidate" }
        var traceData: AnyEncodable { .init(candidate) }
    }

    /// Indicates a change in a transceiver.
    struct DidChangeEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver

        var traceTag: String { "didChange" }
    }

    /// Indicates that an ICE candidate has been generated.
    struct DidGenerateICECandidateEvent: RTCPeerConnectionEvent, Encodable {
        let candidate: RTCIceCandidate

        var traceTag: String { "didGenerateICECandidate" }
        var traceData: AnyEncodable { .init(candidate) }
    }

    /// Indicates that ICE candidates have been removed.
    struct DidRemoveICECandidatesEvent: RTCPeerConnectionEvent, Encodable {
        let candidates: [RTCIceCandidate]

        var traceTag: String { "didRemoveICECandidates" }
        var traceData: AnyEncodable { .init(candidates) }
    }

    /// Indicates a change in both local and remote ICE candidates.
    struct DidChangeLocalCandidateWithRemoteEvent: RTCPeerConnectionEvent, Encodable {
        let localCandidate: RTCIceCandidate
        let remoteCandidate: RTCIceCandidate
        let lastDataReceivedMs: Int32
        let reason: String

        var traceTag: String { "didChangeLocalCandidateWithRemote" }
        var traceData: AnyEncodable { .init(self) }
    }

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

    struct CreateOfferEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "createOffer" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    struct CreateAnswerEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "createAnswer" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    struct SetLocalDescriptionEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "setLocalDescription" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    struct SetRemoteDescriptionEvent: RTCPeerConnectionEvent, Encodable {
        var sessionDescription: RTCSessionDescription

        var traceTag: String { "setRemoteDescription" }
        var traceData: AnyEncodable { .init(sessionDescription) }
    }

    struct CloseEvent: RTCPeerConnectionEvent, Encodable {
        var traceTag: String { "close" }
    }

    struct RestartICEEvent: RTCPeerConnectionEvent, Encodable {
        var traceTag: String { "restartICE" }
    }
}
