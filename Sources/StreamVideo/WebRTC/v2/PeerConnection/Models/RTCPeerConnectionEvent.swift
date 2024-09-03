//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

protocol RTCPeerConnectionEvent {}

extension RTCPeerConnection {

    struct HasRemoteDescription: RTCPeerConnectionEvent {}

    struct ShouldNegotiateEvent: RTCPeerConnectionEvent {}

    struct ICERestartEvent: RTCPeerConnectionEvent {}

    struct SignalingStateChangedEvent: RTCPeerConnectionEvent {
        let state: RTCSignalingState
    }

    struct AddedStreamEvent: RTCPeerConnectionEvent {
        let stream: RTCMediaStream
    }

    struct RemovedStreamEvent: RTCPeerConnectionEvent {
        let stream: RTCMediaStream
    }

    struct AddedReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]
    }

    struct RemovedReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
    }

    struct PeerConnectionStateChangedEvent: RTCPeerConnectionEvent {
        let state: RTCPeerConnectionState
    }

    struct ICEConnectionChangedEvent: RTCPeerConnectionEvent {
        let state: RTCIceConnectionState
    }

    struct ICEGatheringChangedEvent: RTCPeerConnectionEvent {
        let state: RTCIceGatheringState
    }

    struct ICECandidatesRemovedEvent: RTCPeerConnectionEvent {
        let candidates: [RTCIceCandidate]
    }

    struct ICECandidateFailedToGatherEvent: RTCPeerConnectionEvent {
        let errorEvent: RTCIceCandidateErrorEvent
    }

    struct DidChangeStandardizedICEConnectionStateEvent: RTCPeerConnectionEvent {
        let state: RTCIceConnectionState
    }

    struct DidOpenDataChannelEvent: RTCPeerConnectionEvent {
        let dataChannel: RTCDataChannel
    }

    struct DidChangeConnectionStateEvent: RTCPeerConnectionEvent {
        let state: RTCPeerConnectionState
    }

    struct DidStartReceivingOnTransceiverEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver
    }

    struct DidAddReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
        let streams: [RTCMediaStream]
    }

    struct DidRemoveReceiverEvent: RTCPeerConnectionEvent {
        let receiver: RTCRtpReceiver
    }

    struct DidChangeLocalCandidateEvent: RTCPeerConnectionEvent {
        let candidate: RTCIceCandidate
    }

    struct DidChangeRemoteCandidateEvent: RTCPeerConnectionEvent {
        let candidate: RTCIceCandidate
    }

    struct DidChangeEvent: RTCPeerConnectionEvent {
        let transceiver: RTCRtpTransceiver
    }

    struct DidGenerateICECandidateEvent: RTCPeerConnectionEvent {
        let candidate: RTCIceCandidate
    }

    struct DidRemoveICECandidatesEvent: RTCPeerConnectionEvent {
        let candidates: [RTCIceCandidate]
    }

    struct DidChangeLocalCandidateWithRemoteEvent: RTCPeerConnectionEvent {
        let localCandidate: RTCIceCandidate
        let remoteCandidate: RTCIceCandidate
        let lastDataReceivedMs: Int32
        let reason: String
    }
}

extension RTCMediaStream {
    override public var description: String {
        let audioTracksInfo = "Audio Tracks: \(audioTracks.count)"
        let videoTracksInfo = "Video Tracks: \(videoTracks.count)"
        let trackDetails = audioTracks.map { "Audio: \($0.trackId)" } + videoTracks.map { "Video: \($0.trackId)" }

        return """
        RTCMediaStream:
        - StreamId: \(streamId)
        - \(audioTracksInfo)
        - \(videoTracksInfo)
        - Tracks:
          \(trackDetails.joined(separator: "\n  "))
        """
    }
}

extension RTCRtpReceiver {
    override public var description: String {
        let trackInfo = track.map { "Track: \($0.kind) (\($0.trackId))" } ?? "No track"
        let parameterInfo =
            """
            Parameters:
              - Encodings: \(parameters.encodings.count)
              - HeaderExtensions: \(parameters.headerExtensions.count)
              - RTCP: \(parameters.rtcp)
            """

        return """
        RTCRtpReceiver:
        - \(trackInfo)
        - \(parameterInfo)
        - MediaType: \(track?.kind ?? "n/a")
        """
    }
}

extension RTCIceCandidate {
    override public var description: String {
        """
        RTCIceCandidate:
        - SDP Mid: \(sdpMid ?? "nil")
        - SDP MLineIndex: \(sdpMLineIndex)
        - SDP: \(sdp)
        - Server URL: \(serverUrl ?? "nil")
        """
    }
}
