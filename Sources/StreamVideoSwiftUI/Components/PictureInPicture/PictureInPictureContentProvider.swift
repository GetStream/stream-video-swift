//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo

/// Manages the content displayed in the Picture-in-Picture window.
///
/// This class handles updates to the Picture-in-Picture content based on call state,
/// participant changes, and connection status.
final class PictureInPictureContentProvider: @unchecked Sendable {

    @Injected(\.internetConnectionObserver) private var internetConnectionObserver

    private let store: PictureInPictureStore
    private var callUpdateCancellable: AnyCancellable?
    private var participantUpdateCancellable: AnyCancellable?
    private var connectionStatusCancellable: AnyCancellable?
    private var internetStatusCancellable: AnyCancellable?
    private var localParticipantCancellable: AnyCancellable?
    private var isCurrentUserScreenSharingCancellable: AnyCancellable?
    private var screenSharingSessionCancellable: AnyCancellable?
    private let disposableBag = DisposableBag()

    private var localParticipant: CallParticipant?
    private var isCurrentUserScreenSharing: Bool = false
    private var screenSharingSession: ScreenSharingSession?

    /// Creates a new content provider for Picture-in-Picture.
    ///
    /// - Parameter store: The store managing Picture-in-Picture state
    init(store: PictureInPictureStore) {
        self.store = store

        callUpdateCancellable = store
            .publisher(for: \.call).removeDuplicates { $0?.cId == $1?.cId }
            .sink { [weak self] in self?.didUpdate($0) }
    }

    /// Updates internal state when the current call changes.
    private func didUpdate(_ call: Call?) {
        disposableBag.removeAll()

        guard let call else {
            store.dispatch(.setContent(.inactive))
            return
        }

        Task(disposableBag: disposableBag) { @MainActor [weak self] in
            guard let self else { return }
            call
                .state
                .$participants
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.didUpdate($0) }
                .store(in: disposableBag)

            call
                .state
                .$reconnectionStatus
                .removeDuplicates()
                .filter { $0 == .reconnecting }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.store.dispatch(.setContent(.reconnecting)) }
                .store(in: disposableBag)

            internetConnectionObserver
                .statusPublisher
                .removeDuplicates()
                .filter { !$0.isAvailable }
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.store.dispatch(.setContent(.reconnecting)) }
                .store(in: disposableBag)

            call
                .state
                .$localParticipant
                .removeDuplicates(by: { $0?.sessionId == $1?.sessionId })
                .assign(to: \.localParticipant, onWeak: self)
                .store(in: disposableBag)

            call
                .state
                .$isCurrentUserScreensharing
                .removeDuplicates()
                .assign(to: \.isCurrentUserScreenSharing, onWeak: self)
                .store(in: disposableBag)

            call
                .state
                .$screenSharingSession
                .removeDuplicates(by: { $0?.track?.trackId == $1?.track?.trackId })
                .assign(to: \.screenSharingSession, onWeak: self)
                .store(in: disposableBag)
        }
    }

    /// Updates Picture-in-Picture content based on participant changes.
    ///
    /// Prioritizes screen sharing, dominant speaker, and video-enabled participants.
    private func didUpdate(_ participants: [CallParticipant]) {
        guard let call = store.state.call else {
            return
        }

        let otherParticipants = participants.filter { $0.sessionId != localParticipant?.sessionId }

        if
            let session = screenSharingSession,
            isCurrentUserScreenSharing == false,
            let track = session.track {
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
            let localParticipant {
            updatePreferredContentSizeIfRequired(for: localParticipant)
            store.dispatch(.setContent(.participant(call, localParticipant, localParticipant.track)))
        } else {
            store.dispatch(.setContent(.inactive))
        }
    }

    /// Updates the preferred content size for Picture-in-Picture if needed.
    private func updatePreferredContentSizeIfRequired(for participant: CallParticipant) {
        guard participant.hasVideo, participant.trackSize != .zero else {
            return
        }
        store.dispatch(.setPreferredContentSize(participant.trackSize))
    }
}
