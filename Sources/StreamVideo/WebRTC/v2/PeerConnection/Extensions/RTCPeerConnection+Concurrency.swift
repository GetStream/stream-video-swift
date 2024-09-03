//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCPeerConnection {

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
