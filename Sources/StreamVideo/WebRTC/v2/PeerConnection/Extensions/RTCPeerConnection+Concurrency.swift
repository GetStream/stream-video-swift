//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Extension to add async/await support to RTCPeerConnection methods.
extension RTCPeerConnection {

    /// Creates an offer asynchronously with the given media constraints.
    ///
    /// - Parameter constraints: The media constraints to use when creating the offer. Defaults to `.defaultConstraints`.
    /// - Returns: The created RTCSessionDescription.
    /// - Throws: An error if the offer creation fails or if the RTCPeerConnection instance becomes unavailable.
    func createOffer(
        constraints: RTCMediaConstraints = .defaultConstraints
    ) async throws -> RTCSessionDescription {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(
                    throwing: ClientError.Unknown("RTCPeerConnection instance is unavailable.")
                )
                return
            }
            self.offer(for: constraints) { sdp, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let sdp = sdp {
                    continuation.resume(returning: sdp)
                } else {
                    continuation.resume(
                        throwing: ClientError.Unknown("RTCPeerConnection failed to create offer.")
                    )
                }
            }
        }
    }

    /// Sets the local description asynchronously.
    ///
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the local description.
    /// - Throws: An error if setting the local description fails or if the RTCPeerConnection instance becomes unavailable.
    func setLocalDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(
                    throwing: ClientError.Unknown("RTCPeerConnection instance is unavailable.")
                )
                return
            }

            self.setLocalDescription(sessionDescription) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        } as ()
    }

    /// Sets the remote description asynchronously.
    ///
    /// - Parameter sessionDescription: The RTCSessionDescription to set as the remote description.
    /// - Throws: An error if setting the remote description fails or if the RTCPeerConnection instance becomes unavailable.
    func setRemoteDescription(
        _ sessionDescription: RTCSessionDescription
    ) async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self else {
                continuation.resume(
                    throwing: ClientError.Unknown("RTCPeerConnection instance is unavailable.")
                )
                return
            }

            self.setRemoteDescription(sessionDescription) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    self.subject.send(HasRemoteDescription())
                    continuation.resume(returning: ())
                }
            }
        } as ()
    }
}
