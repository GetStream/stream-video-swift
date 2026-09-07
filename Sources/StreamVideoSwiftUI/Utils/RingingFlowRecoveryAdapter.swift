//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

/// Turns a refreshed ringing-call session into the accept / reject / end
/// events `CallViewModel` already handles from the WebSocket.
///
/// After a reconnect, the StreamVideo client reloads `Call.state` with
/// `get()`. That does not join the call. This adapter watches
/// `StreamVideo.state.ringingCall` and, for an outgoing ring (the local
/// user created it), synthesizes those events from `session`.
///
/// `createdBy` is checked when the session updates, not when
/// `ringingCall` is first assigned. CallKit and similar paths set
/// `ringingCall` before `get()` fills `createdBy`; a later `GET` updates
/// session and does not re-emit `ringingCall`.
final class RingingFlowRecoveryAdapter: @unchecked Sendable {

    private enum DisposableKey: String { case sessionObserver }

    private let streamVideo: StreamVideo
    private let onAccepted: (CallEvent) -> Void
    private let onRejected: (CallEvent) -> Void
    private let onEnded: (CallEvent) -> Void

    private let disposableBag = DisposableBag()

    @MainActor
    init(
        _ streamVideo: StreamVideo,
        onAccepted: @escaping (CallEvent) -> Void,
        onRejected: @escaping (CallEvent) -> Void,
        onEnded: @escaping (CallEvent) -> Void
    ) {
        self.streamVideo = streamVideo
        self.onAccepted = onAccepted
        self.onRejected = onRejected
        self.onEnded = onEnded

        observeRingingCall()
    }

    // MARK: - Private Helpers

    @MainActor
    private func observeRingingCall() {
        streamVideo
            .state
            .$ringingCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.didUpdateRingingCall($0) }
            .store(in: disposableBag)
    }

    @MainActor
    private func didUpdateRingingCall(_ ringingCall: Call?) {
        disposableBag.remove(DisposableKey.sessionObserver.rawValue)

        guard let ringingCall else {
            return
        }

        observeCallStateSessionWhileRinging(ringingCall)
    }

    @MainActor
    private func observeCallStateSessionWhileRinging(_ ringingCall: Call) {
        ringingCall
            .state
            .$session
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self, callCId = ringingCall.cId] session in
                self?.ringingCallSessionUpdated(session, callCId: callCId)
            }
            .store(
                in: disposableBag,
                key: DisposableKey.sessionObserver.rawValue
            )
    }

    private func ringingCallSessionUpdated(
        _ session: CallSessionResponse,
        callCId: String
    ) {
        Task { @MainActor [weak self] in
            guard
                let self,
                let ringingCall = streamVideo.state.ringingCall,
                ringingCall.cId == callCId,
                ringingCall.state.createdBy?.id == streamVideo.user.id
            else {
                return
            }

            let currentUserId = streamVideo.user.id
            if
                let userId = session.acceptedBy.keys.first(where: {
                    $0 != currentUserId
                }) {
                onAccepted(
                    .accepted(
                        .init(
                            callCid: callCId,
                            user: .init(id: userId),
                            action: .accept
                        )
                    )
                )
            } else if
                let userId = session.rejectedBy.keys.first(where: {
                    $0 != currentUserId
                }) {
                onRejected(
                    .rejected(
                        .init(
                            callCid: callCId,
                            user: .init(id: userId),
                            action: .reject
                        )
                    )
                )
            } else if session.endedAt != nil {
                onEnded(
                    .ended(
                        .init(
                            callCid: callCId,
                            user: nil,
                            action: .end
                        )
                    )
                )
            }
        }
    }
}
