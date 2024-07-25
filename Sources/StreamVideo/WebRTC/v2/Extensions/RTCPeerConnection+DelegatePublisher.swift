//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension RTCPeerConnection {
    private enum AssociatedKeys {
        static var delegatePublisher = "DelegatePublisher"
    }

    var publisher: AnyPublisher<RTCPeerConnectionEvent, Never> {
        withUnsafePointer(to: &AssociatedKeys.delegatePublisher) { key in
            if let existingPublisher = objc_getAssociatedObject(
                self,
                key
            ) as? DelegatePublisher {
                return existingPublisher.publisher.eraseToAnyPublisher()
            } else {
                let newPublisher = DelegatePublisher()
                objc_setAssociatedObject(
                    self,
                    key,
                    newPublisher,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
                self.delegate = newPublisher
                return newPublisher.publisher.eraseToAnyPublisher()
            }
        }
    }

    func publisher<T: RTCPeerConnectionEvent>(
        eventType: T.Type
    ) -> AnyPublisher<T, Never> {
        publisher.compactMap { $0 as? T }.eraseToAnyPublisher()
    }
}

extension RTCPeerConnection {

    final class DelegatePublisher: NSObject, RTCPeerConnectionDelegate {

        let publisher = PassthroughSubject<RTCPeerConnectionEvent, Never>()

        func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
            publisher.send(ShouldNegotiateEvent())
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange stateChanged: RTCSignalingState
        ) {
            publisher.send(SignalingStateChangedEvent(state: stateChanged))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didAdd stream: RTCMediaStream
        ) {
            publisher.send(AddedStreamEvent(stream: stream))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didRemove stream: RTCMediaStream
        ) {
            publisher.send(RemovedStreamEvent(stream: stream))
        }

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

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didRemove rtpReceiver: RTCRtpReceiver
        ) {
            publisher.send(RemovedReceiverEvent(receiver: rtpReceiver))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange newState: RTCPeerConnectionState
        ) {
            publisher.send(PeerConnectionStateChangedEvent(state: newState))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange newState: RTCIceConnectionState
        ) {
            publisher.send(ICEConnectionChangedEvent(state: newState))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange newState: RTCIceGatheringState
        ) {
            publisher.send(ICEGatheringChangedEvent(state: newState))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChangeStandardizedIceConnectionState newState: RTCIceConnectionState
        ) {
            publisher.send(
                DidChangeStandardizedICEConnectionStateEvent(state: newState)
            )
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didGenerate candidate: RTCIceCandidate
        ) {
            publisher.send(DidGenerateICECandidateEvent(candidate: candidate))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didRemove candidates: [RTCIceCandidate]
        ) {
            publisher.send(ICECandidatesRemovedEvent(candidates: candidates))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didFailToGatherIceCandidate event: RTCIceCandidateErrorEvent
        ) {
            publisher.send(ICECandidateFailedToGatherEvent(errorEvent: event))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didOpen dataChannel: RTCDataChannel
        ) {
            publisher.send(DidOpenDataChannelEvent(dataChannel: dataChannel))
        }

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

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange local: RTCIceCandidate
        ) {
            publisher.send(DidChangeLocalCandidateEvent(candidate: local))
        }

        func peerConnection(
            _ peerConnection: RTCPeerConnection,
            didChange transceiver: RTCRtpTransceiver
        ) {
            publisher.send(DidChangeEvent(transceiver: transceiver))
        }

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
