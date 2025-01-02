//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension StreamRTCPeerConnection {
    /// Indicates that a remote description has been set.
    struct HasRemoteDescription: RTCPeerConnectionEvent {}

    /// Indicates that the peer connection should negotiate.
    struct ShouldNegotiateEvent: RTCPeerConnectionEvent {}

    /// Indicates that an ICE restart has occurred.
    struct ICERestartEvent: RTCPeerConnectionEvent {}

    /// Indicates a change in the signaling state.
    struct SignalingStateChangedEvent: RTCPeerConnectionEvent {
        let state: RTCSignalingState
    }

    /// Indicates that a media stream has been added.
    struct AddedStreamEvent: RTCPeerConnectionEvent {
        let stream: RTCMediaStream
    }

    /// Indicates that a media stream has been removed.
    struct RemovedStreamEvent: RTCPeerConnectionEvent {
        let stream: RTCMediaStream
    }

    /// Indicates that an RTP receiver has been added.
    struct AddedReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]
    }

    /// Indicates that an RTP receiver has been removed.
    struct RemovedReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
    }

    /// Indicates a change in the peer connection state.
    struct PeerConnectionStateChangedEvent: RTCPeerConnectionEvent {
        let state: RTCPeerConnectionState
    }

    /// Indicates a change in the ICE connection state.
    struct ICEConnectionChangedEvent: RTCPeerConnectionEvent {
        let state: RTCIceConnectionState
    }

    /// Indicates a change in the ICE gathering state.
    struct ICEGatheringChangedEvent: RTCPeerConnectionEvent {
        let state: RTCIceGatheringState
    }

    /// Indicates that ICE candidates have been removed.
    struct ICECandidatesRemovedEvent: RTCPeerConnectionEvent {
        let candidates: [RTCIceCandidate]
    }

    /// Indicates a failure in gathering an ICE candidate.
    struct ICECandidateFailedToGatherEvent: RTCPeerConnectionEvent {
        let errorEvent: RTCIceCandidateErrorEvent
    }

    /// Indicates a change in the standardized ICE connection state.
    struct DidChangeStandardizedICEConnectionStateEvent: RTCPeerConnectionEvent {
        let state: RTCIceConnectionState
    }

    /// Indicates that a data channel has been opened.
    struct DidOpenDataChannelEvent: RTCPeerConnectionEvent {
        let dataChannel: RTCDataChannel
    }

    /// Indicates a change in the connection state.
    struct DidChangeConnectionStateEvent: RTCPeerConnectionEvent {
        let state: RTCPeerConnectionState
    }

    /// Indicates that a transceiver has started receiving.
    struct DidStartReceivingOnTransceiverEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver
    }

    /// Indicates that an RTP receiver has been added.
    struct DidAddReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]
    }

    /// Indicates that an RTP receiver has been removed.
    struct DidRemoveReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
    }

    /// Indicates a change in the local ICE candidate.
    struct DidChangeLocalCandidateEvent: RTCPeerConnectionEvent {
        let candidate: RTCIceCandidate
    }

    /// Indicates a change in the remote ICE candidate.
    struct DidChangeRemoteCandidateEvent: RTCPeerConnectionEvent {
        let candidate: RTCIceCandidate
    }

    /// Indicates a change in a transceiver.
    struct DidChangeEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver
    }

    /// Indicates that an ICE candidate has been generated.
    struct DidGenerateICECandidateEvent: RTCPeerConnectionEvent {
        let candidate: RTCIceCandidate
    }

    /// Indicates that ICE candidates have been removed.
    struct DidRemoveICECandidatesEvent: RTCPeerConnectionEvent {
        let candidates: [RTCIceCandidate]
    }

    /// Indicates a change in both local and remote ICE candidates.
    struct DidChangeLocalCandidateWithRemoteEvent: RTCPeerConnectionEvent {
        let localCandidate: RTCIceCandidate
        let remoteCandidate: RTCIceCandidate
        let lastDataReceivedMs: Int32
        let reason: String
    }
}
