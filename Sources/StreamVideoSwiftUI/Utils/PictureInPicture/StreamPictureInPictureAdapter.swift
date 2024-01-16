//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine
import StreamVideo
import UIKit

@MainActor
final class StreamPictureInPictureAdapter {

    static let shared = StreamPictureInPictureAdapter()

    var call: Call? {
        didSet { didUpdate(call) }
    }

    var sourceView: UIView? {
        didSet {
            guard sourceView !== oldValue else { return }
            didUpdate(sourceView)
        }
    }

    var onSizeUpdate: ((CGSize, CallParticipant) -> Void)? {
        didSet {
            pictureInPictureController?.onSizeUpdate = { [weak self] size in
                if let activeParticipant = self?.activeParticipant {
                    self?.onSizeUpdate?(size, activeParticipant)
                }
            }
        }
    }

    private var activeParticipant: CallParticipant?

    private var participantUpdatesCancellable: AnyCancellable?

    private lazy var pictureInPictureController = StreamPictureInPictureController()

    private init() {}

    // MARK: - Private Helpers

    private func didUpdate(_ call: Call?) {
        participantUpdatesCancellable?.cancel()

        guard let call = call else { return }

        participantUpdatesCancellable = call
            .state
            .$participants
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.didUpdate($0) }
    }

    private func didUpdate(_ participants: [CallParticipant]) {
        let sessionId = call?.state.sessionId
        let otherParticipants = participants.filter { $0.sessionId != sessionId }

        if let session = call?.state.screenSharingSession, call?.state.isCurrentUserScreensharing == false, let track = session.track {
            pictureInPictureController?.track = track
            activeParticipant = nil
        } else if let participant = otherParticipants.first(where: { $0.track != nil }), let track = participant.track {
            pictureInPictureController?.track = track
            activeParticipant = participant
        } else if let localParticipant = call?.state.localParticipant, let track = localParticipant.track {
            pictureInPictureController?.track = track
            activeParticipant = localParticipant
        }
    }

    private func didUpdate(_ sourceView: UIView?) {
        pictureInPictureController?.sourceView = sourceView
    }
}
