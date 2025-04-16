//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo

final class PictureInPictureContentProvider: @unchecked Sendable {

    @Injected(\.internetConnectionObserver) private var internetConnectionObserver

    private let store: PictureInPictureStore
    private var callUpdateCancellable: AnyCancellable?
    private var participantUpdateCancellable: AnyCancellable?
    private var connectionStatusCancellable: AnyCancellable?
    private var internetStatusCancellable: AnyCancellable?

    init(store: PictureInPictureStore) {
        self.store = store

        callUpdateCancellable = store
            .publisher(for: \.call).removeDuplicates { $0?.cId == $1?.cId }
            .sink { [weak self] in self?.didUpdate($0) }
    }

    private func didUpdate(_ call: Call?) {
        participantUpdateCancellable?.cancel()
        participantUpdateCancellable = nil

        guard let call else {
            return
        }

        Task { @MainActor in
            participantUpdateCancellable = call
                .state
                .$participants
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.didUpdate($0) }

            connectionStatusCancellable = call
                .state
                .$reconnectionStatus
                .removeDuplicates()
                .filter { $0 == .reconnecting }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.store.dispatch(.setContent(.reconnecting)) }

            internetStatusCancellable = internetConnectionObserver
                .statusPublisher
                .removeDuplicates()
                .filter { !$0.isAvailable }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.store.dispatch(.setContent(.reconnecting)) }
        }
    }

    /// Whenever participants change we update our internal state in order to always have the correct track
    /// on picture-in-picture.
    private func didUpdate(_ participants: [CallParticipant]) {
        guard let call = store.state.call else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let sessionId = call.state.sessionId
            let otherParticipants = participants.filter { $0.sessionId != sessionId }

            if
                let session = call.state.screenSharingSession,
                call.state.isCurrentUserScreensharing == false,
                let track = session.track {
                updatePreferredContentSizeIfRequired(for: session.participant)
                store.dispatch(.setContent(.screenSharing(call, session.participant, track)))
            } else if
                let participant = otherParticipants.first(where: { $0.isDominantSpeaker }) {
                updatePreferredContentSizeIfRequired(for: participant)
                store.dispatch(.setContent(.participant(call, participant, participant.hasVideo ? participant.track : nil)))
            } else if
                let participant = otherParticipants.first(where: { $0.hasVideo && $0.track != nil }),
                let track = participant.track {
                updatePreferredContentSizeIfRequired(for: participant)
                store.dispatch(.setContent(.participant(call, participant, track)))
            } else if
                let participant = otherParticipants.first {
                store.dispatch(.setContent(.participant(call, participant, nil)))
            } else if
                let localParticipant = call.state.localParticipant {
                updatePreferredContentSizeIfRequired(for: localParticipant)
                store.dispatch(.setContent(.participant(call, localParticipant, localParticipant.track)))
            } else {
                store.dispatch(.setContent(.inactive))
            }
        }
    }

    private func updatePreferredContentSizeIfRequired(for participant: CallParticipant) {
        guard !store.state.isActive, participant.trackSize != .zero else {
            return
        }
        store.dispatch(.setPreferredContentSize(participant.trackSize))
    }
}
