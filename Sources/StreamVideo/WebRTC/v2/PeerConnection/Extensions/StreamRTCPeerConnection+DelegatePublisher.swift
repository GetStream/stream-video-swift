//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension StreamRTCPeerConnection {

    /// A delegate class that publishes RTCPeerConnection events.
    ///
    /// This class implements the `RTCPeerConnectionDelegate` protocol and uses a `PassthroughSubject`
    /// to publish various events that occur during the lifecycle of an RTCPeerConnection.
    final class DelegatePublisher: NSObject, RTCPeerConnectionDelegate {

        /// A publisher that emits RTCPeerConnectionEvents.
        let publisher = PassthroughSubject<RTCPeerConnectionEvent, Never>()

        /// Called when the RTCPeerConnection should negotiate.
        /// - Parameter peerConnection: The RTCPeerConnection that should negotiate.
        func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
            publisher.send(ShouldNegotiateEvent())
        }

        /// Called when the signaling state of the RTCPeerConnection changes.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose state changed.
        ///   - stateChanged: The new signaling state.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange stateChanged: RTCSignalingState
        ) {
            publisher.send(SignalingStateChangedEvent(state: stateChanged))
        }

        /// Called when a new media stream is added to the RTCPeerConnection.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection that received the stream.
        ///   - stream: The newly added media stream.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didAdd stream: RTCMediaStream
        ) {
            publisher.send(AddedStreamEvent(stream: stream))
        }

        /// Called when a media stream is removed from the RTCPeerConnection.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection from which the stream was removed.
        ///   - stream: The removed media stream.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didRemove stream: RTCMediaStream
        ) {
            publisher.send(RemovedStreamEvent(stream: stream))
        }

        /// Called when a new RTP receiver is added to the RTCPeerConnection.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection that received the new receiver.
        ///   - rtpReceiver: The newly added RTP receiver.
        ///   - mediaStreams: The media streams associated with the new receiver.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didAdd rtpReceiver: RTCRtpReceiver,
            streams mediaStreams: [RTCMediaStream]
        ) {
            publisher.send(
                AddedReceiverEvent(
                    receiver: rtpReceiver,
                    streams: mediaStreams
                )
            )
        }

        /// Called when an RTP receiver is removed from the RTCPeerConnection.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection from which the receiver was removed.
        ///   - rtpReceiver: The removed RTP receiver.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didRemove rtpReceiver: RTCRtpReceiver
        ) {
            publisher.send(RemovedReceiverEvent(receiver: rtpReceiver))
        }

        /// Called when the connection state of the RTCPeerConnection changes.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose state changed.
        ///   - newState: The new connection state.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange newState: RTCPeerConnectionState
        ) {
            publisher.send(PeerConnectionStateChangedEvent(state: newState))
        }

        /// Called when the ICE connection state of the RTCPeerConnection changes.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose ICE connection state changed.
        ///   - newState: The new ICE connection state.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange newState: RTCIceConnectionState
        ) {
            publisher.send(ICEConnectionChangedEvent(state: newState))
        }

        /// Called when the ICE gathering state of the RTCPeerConnection changes.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose ICE gathering state changed.
        ///   - newState: The new ICE gathering state.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange newState: RTCIceGatheringState
        ) {
            publisher.send(ICEGatheringChangedEvent(state: newState))
        }

        /// Called when the standardized ICE connection state of the RTCPeerConnection changes.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose standardized ICE connection state changed.
        ///   - newState: The new standardized ICE connection state.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChangeStandardizedIceConnectionState newState: RTCIceConnectionState
        ) {
            publisher.send(
                DidChangeStandardizedICEConnectionStateEvent(state: newState)
            )
        }

        /// Called when a new ICE candidate is generated.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection that generated the candidate.
        ///   - candidate: The newly generated ICE candidate.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didGenerate candidate: RTCIceCandidate
        ) {
            publisher.send(DidGenerateICECandidateEvent(candidate: candidate))
        }

        /// Called when ICE candidates are removed.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection from which candidates were removed.
        ///   - candidates: An array of removed ICE candidates.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didRemove candidates: [RTCIceCandidate]
        ) {
            publisher.send(ICECandidatesRemovedEvent(candidates: candidates))
        }

        /// Called when the RTCPeerConnection fails to gather an ICE candidate.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection that failed to gather the candidate.
        ///   - event: The error event containing details about the failure.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didFailToGatherIceCandidate event: RTCIceCandidateErrorEvent
        ) {
            publisher.send(ICECandidateFailedToGatherEvent(errorEvent: event))
        }

        /// Called when a data channel is opened on the RTCPeerConnection.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection on which the data channel was opened.
        ///   - dataChannel: The newly opened data channel.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didOpen dataChannel: RTCDataChannel
        ) {
            publisher.send(DidOpenDataChannelEvent(dataChannel: dataChannel))
        }

        /// Called when the RTCPeerConnection starts receiving on a transceiver.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection that started receiving.
        ///   - transceiver: The transceiver that started receiving.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didStartReceivingOn transceiver: RTCRtpTransceiver
        ) {
            publisher.send(
                DidStartReceivingOnTransceiverEvent(
                    transceiver: transceiver
                )
            )
        }

        /// Called when the local ICE candidate of the RTCPeerConnection changes.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose local candidate changed.
        ///   - local: The new local ICE candidate.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange local: RTCIceCandidate
        ) {
            publisher.send(DidChangeLocalCandidateEvent(candidate: local))
        }

        /// Called when a transceiver on the RTCPeerConnection changes.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose transceiver changed.
        ///   - transceiver: The changed transceiver.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange transceiver: RTCRtpTransceiver
        ) {
            publisher.send(DidChangeEvent(transceiver: transceiver))
        }

        /// Called when both local and remote ICE candidates of the RTCPeerConnection change.
        /// - Parameters:
        ///   - peerConnection: The RTCPeerConnection whose candidates changed.
        ///   - local: The new local ICE candidate.
        ///   - remote: The new remote ICE candidate.
        ///   - lastDataReceivedMs: The time in milliseconds when data was last received.
        ///   - reason: The reason for the change.
        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChangeLocalCandidate local: RTCIceCandidate,
            remoteCandidate remote: RTCIceCandidate,
            lastReceivedMs lastDataReceivedMs: Int32,
            changeReason reason: String
        ) {
            publisher.send(
                DidChangeLocalCandidateWithRemoteEvent(
                    localCandidate: local,
                    remoteCandidate: remote,
                    lastDataReceivedMs: lastDataReceivedMs,
                    reason: reason
                )
            )
        }
    }
}
