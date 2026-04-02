//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCPeerConnectionCoordinator {

    final class NegotiationAdapter {
        private weak var peerConnectionCoordinator: RTCPeerConnectionCoordinator?
        private let identifier: UUID
        private let peerConnection: StreamRTCPeerConnectionProtocol
        private let peerType: PeerConnectionType
        private let sessionID: String
        private let sfuAdapter: SFUAdapter
        private let clientCapabilities: Set<ClientCapability>
        private let subsystem: LogSubsystem

        /// Retries `setPublisher` once to recover from transient SFU failures
        /// observed during join when local media state is still settling.
        ///
        /// In practice this protects publisher negotiation from short-lived
        /// races triggered by rapid `CallSettings` updates (for example audio
        /// output route changes) that can otherwise make the initial
        /// `setPublisher` attempt fail.
        private let retryPolicy: RetryPolicy = .init(maxRetries: 1, delay: { _ in 0.25 })

        init(
            _ peerConnectionCoordinator: RTCPeerConnectionCoordinator,
            identifier: UUID,
            peerConnection: StreamRTCPeerConnectionProtocol,
            peerType: PeerConnectionType,
            sessionID: String,
            sfuAdapter: SFUAdapter,
            clientCapabilities: Set<ClientCapability>,
            subsystem: LogSubsystem
        ) {
            self.peerConnectionCoordinator = peerConnectionCoordinator
            self.identifier = identifier
            self.peerConnection = peerConnection
            self.peerType = peerType
            self.sessionID = sessionID
            self.sfuAdapter = sfuAdapter
            self.clientCapabilities = clientCapabilities
            self.subsystem = subsystem
        }

        func negotiate(
            constraints: RTCMediaConstraints = .defaultConstraints
        ) async throws {
            guard let peerConnectionCoordinator else {
                throw ClientError("RTCPeerConnectionCoordinator is unavailable (peerType: \(peerType)).")
            }

            let negotiationStartedAt = Date()

            log.debug(
                "PeerConnection will negotiate { identifier:\(identifier) type:\(peerType) sessionID: \(sessionID) sfu: \(sfuAdapter.hostname) }",
                subsystems: subsystem
            )

            do {
                let (offer, tracksInfo) = try await prepareForNegotiation(
                    for: peerConnectionCoordinator,
                    constraints: constraints
                )

                try await executeTask(retryPolicy: retryPolicy) {
                    try await self.setPublisher(
                        for: peerConnectionCoordinator,
                        offer: offer,
                        tracksInfo: tracksInfo
                    )
                }

                log.debug(
                    "Negotiation completed after \(Date().timeIntervalSince(negotiationStartedAt)) seconds { identifier:\(identifier) type:\(peerType) sessionID: \(sessionID) sfu: \(sfuAdapter.hostname) }",
                    subsystems: subsystem
                )
            } catch {
                log.debug(
                    "Negotiation failed after \(Date().timeIntervalSince(negotiationStartedAt)) seconds { identifier:\(identifier) type:\(peerType) sessionID: \(sessionID) sfu: \(sfuAdapter.hostname) } error:\(error)",
                    subsystems: subsystem
                )
                throw error
            }
        }

        // MARK: - Private Helpers

        private func prepareForNegotiation(
            for peerConnectionCoordinator: RTCPeerConnectionCoordinator,
            constraints: RTCMediaConstraints
        ) async throws -> (RTCSessionDescription, [Stream_Video_Sfu_Models_TrackInfo]) {
            let offer = try await peerConnectionCoordinator.createOffer(constraints: constraints)

            try await peerConnectionCoordinator.setLocalDescription(offer)

            try await peerConnectionCoordinator.ensureSetUpHasBeenCompleted()

            let tracksInfo = buildTracksInfo(from: peerConnectionCoordinator)
            // This is only used for debugging and internal validation.
            validateTracksAndTransceivers(.video, tracksInfo: tracksInfo)
            validateTracksAndTransceivers(.screenshare, tracksInfo: tracksInfo)

            log.debug(
                "PeerConnection will setPublisher identifier:\(identifier) type:\(peerType) sessionID:\(sessionID) sfu:\(sfuAdapter.hostname) tracksInfo { audio:\(tracksInfo.filter { $0.trackType == .audio }) video:  \(tracksInfo.filter { $0.trackType == .video }) hasScreenSharing: \(tracksInfo.contains { $0.trackType == .screenShare }) } ",
                subsystems: subsystem
            )

            return (offer, tracksInfo)
        }

        private func buildTracksInfo(
            from peerConnectionCoordinator: RTCPeerConnectionCoordinator
        ) -> [Stream_Video_Sfu_Models_TrackInfo] {
            return WebRTCJoinRequestFactory(
                capabilities: clientCapabilities.map(\.rawValue)
            )
            .buildAnnouncedTracks(peerConnectionCoordinator, collectionType: .allAvailable)
        }

        /// Validates that the tracks intended for negotiation with the SFU match the state of the transceivers in
        /// the peer connection.
        ///
        /// This method ensures that the tracks we plan to send during negotiation (as represented by the
        /// `tracksInfo` parameter) are consistent with the transceivers in the peer connection. If there is a
        /// mismatch, an error is logged for debugging purposes.
        ///
        /// - Parameters:
        ///   - trackType: The type of track to validate (e.g., `.audio`, `.video`, or `.screenshare`).
        ///   - tracksInfo: A collection of `TrackInfo` objects representing the tracks announced to
        ///   the SFU during negotiation.
        ///
        /// The validation process compares the set of track IDs in the `tracksInfo` list against the set of
        /// track IDs retrieved from the peer connection's transceivers for the specified `trackType`. If these
        /// sets differ, it indicates a discrepancy between the announced tracks and the transceivers' actual state.
        private func validateTracksAndTransceivers(
            _ trackType: TrackType,
            tracksInfo: [Stream_Video_Sfu_Models_TrackInfo]
        ) {
            let tracks = Set(
                tracksInfo
                    .filter {
                        switch (trackType, $0.trackType) {
                        case (.audio, .audio), (.video, .video), (.screenshare, .screenShare):
                            return true
                        default:
                            return false
                        }
                    }
                    .map(\.trackID)
            )
            let transceivers = Set(
                peerConnection
                    .transceivers(for: trackType)
                    .compactMap(\.sender.track?.trackId)
            )

            guard tracks != transceivers else {
                return
            }
            log.error(
                "PeerConnection tracks and transceivers mismatch for trackType:\(trackType) identifier:\(identifier) peerType:\(peerType) sessionID:\(sessionID) sfu:\(sfuAdapter.hostname) tracks:\(tracks.sorted().joined(separator: ",")) transceivers: \(transceivers.sorted().joined(separator: ","))",
                subsystems: subsystem
            )
        }

        private func setPublisher(
            for peerConnectionCoordinator: RTCPeerConnectionCoordinator,
            offer: RTCSessionDescription,
            tracksInfo: [Stream_Video_Sfu_Models_TrackInfo]
        ) async throws {
            let sessionDescription = try await sfuAdapter.setPublisher(
                sessionDescription: offer.sdp,
                tracks: tracksInfo,
                for: sessionID
            )

            try await peerConnectionCoordinator.setRemoteDescription(
                .init(
                    type: .answer,
                    sdp: sessionDescription.sdp
                )
            )
        }
    }
}
