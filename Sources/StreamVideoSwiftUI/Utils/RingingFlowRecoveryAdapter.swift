//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

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

        observeCurrentCall()
    }

    // MARK: - Private Helpers

    @MainActor
    private func observeCurrentCall() {
        streamVideo
            .state
            .$ringingCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.didUpdateCall() }
            .store(in: disposableBag)
        streamVideo
            .state
            .$activeCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.didUpdateCall() }
            .store(in: disposableBag)
    }

    @MainActor
    private func didUpdateCall() {
        disposableBag.remove(DisposableKey.sessionObserver.rawValue)

        guard let call = streamVideo.state.ringingCall ?? streamVideo.state.activeCall else {
            return
        }

        observeCallStateSessionWhileRinging(call)
    }

    @MainActor
    private func observeCallStateSessionWhileRinging(_ ringingCall: Call) {
        ringingCall
            .state
            .$session
            .combineLatest(ringingCall.state.$endedAt)
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak ringingCall] _ in
                guard let ringingCall else { return }
                self?.ringingCallStateUpdated(ringingCall)
            }
            .store(
                in: disposableBag,
                key: DisposableKey.sessionObserver.rawValue
            )
    }

    @MainActor
    private func ringingCallStateUpdated(_ call: Call) {
        guard (streamVideo.state.ringingCall ?? streamVideo.state.activeCall) === call else {
            return
        }
        let callCId = call.cId
        let currentUserId = streamVideo.user.id
        let session = call.state.session
        if session?.endedAt != nil || call.state.endedAt != nil {
            onEnded(
                .ended(
                    .init(
                        callCid: callCId,
                        user: nil,
                        action: .end
                    )
                )
            )
            return
        }
        guard let session, let creatorId = call.state.createdBy?.id else { return }
        if creatorId != currentUserId {
            if session.acceptedBy[currentUserId] != nil {
                onAccepted(.accepted(.init(
                    callCid: callCId,
                    user: .init(id: currentUserId),
                    action: .accept
                )))
            } else if let userId = [currentUserId, creatorId].first(where: { userId in
                session.rejectedBy[userId] != nil
                    && (userId == currentUserId || session.acceptedBy.keys.allSatisfy { $0 == creatorId })
            }) {
                onRejected(.rejected(.init(
                    callCid: callCId,
                    user: .init(id: userId),
                    action: .reject
                )))
            } else if session.missedBy[currentUserId] != nil {
                onEnded(.ended(.init(callCid: callCId, user: nil, action: .end)))
            }
        } else {
            for userId in session.acceptedBy.keys
                where userId != currentUserId {
                onAccepted(
                    .accepted(
                        .init(
                            callCid: callCId,
                            user: .init(id: userId),
                            action: .accept
                        )
                    )
                )
            }
            for userId in session.rejectedBy.keys
                where userId != currentUserId {
                onRejected(
                    .rejected(
                        .init(
                            callCid: callCId,
                            user: .init(id: userId),
                            action: .reject
                        )
                    )
                )
            }
        }
    }
}
