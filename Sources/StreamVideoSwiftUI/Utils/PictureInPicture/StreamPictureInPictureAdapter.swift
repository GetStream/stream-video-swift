//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import UIKit

/// This class encapsulates the logic for managing picture-in-picture functionality during a video call. It tracks
/// changes in the call, updates related to call participants, and changes in the source view for Picture in
/// Picture display.
public final class StreamPictureInPictureAdapter: @unchecked Sendable {

    /// The active call.
    public var call: Call? {
        didSet {
            Task { @MainActor [weak self] in
                guard let self else { return }
                didUpdate(call)
            }
        }
    }

    /// The sourceView that will be used as an anchor/trigger for picture-in-picture (as required by AVKit).
    public var sourceView: UIView? {
        didSet {
            guard sourceView !== oldValue else { return }
            didUpdate(sourceView)
        }
    }

    /// The closure to call whenever the picture-in-picture rendering window changes size.
    /// The closure gets assigned every time the call is being set.
    var onSizeUpdate: (@Sendable(CGSize, CallParticipant) -> Void)? {
        didSet {
            Task { @MainActor in
                pictureInPictureController?.onSizeUpdate = { [weak self] size in
                    if let activeParticipant = self?.activeParticipant {
                        self?.onSizeUpdate?(size, activeParticipant)
                    }
                }
            }
        }
    }

    /// The participant to use in order to access the track to render on picture-in-picture.
    private nonisolated(unsafe) var activeParticipant: CallParticipant?

    private nonisolated(unsafe) var participantUpdatesCancellable: AnyCancellable?

    /// The actual picture-in-picture controller.
    private lazy var pictureInPictureController = StreamPictureInPictureController()

    // MARK: - Private Helpers

    /// Whenever the call changes, we reset the participant updates observer.
    @MainActor
    private func didUpdate(_ call: Call?) {
        participantUpdatesCancellable?.cancel()
        activeParticipant = nil
        pictureInPictureController?.track = nil
        onSizeUpdate = nil

        guard let call = call else { return }
        onSizeUpdate = { [weak call] trackSize, participant in
            Task { [weak call] in
                log.debug(
                    "Updating track size for participant \(participant.name) to \(trackSize)",
                    subsystems: .pictureInPicture
                )
                await call?.updateTrackSize(trackSize, for: participant)
            }
        }

        Task { @MainActor in
            participantUpdatesCancellable = call
                .state
                .$participants
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.didUpdate($0) }
        }
    }

    /// Whenever participants change we update our internal state in order to always have the correct track
    /// on picture-in-picture.
    private func didUpdate(_ participants: [CallParticipant]) {
        Task { @MainActor in
            let sessionId = call?.state.sessionId
            let otherParticipants = participants.filter { $0.sessionId != sessionId }

            if let session = call?.state.screenSharingSession, call?.state.isCurrentUserScreensharing == false,
               let track = session.track {
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
    }

    private func didUpdate(_ sourceView: UIView?) {
        pictureInPictureController?.sourceView = sourceView
        if call == nil {
            log.warning(
                """
                PictureInPicture adapter has received a sourceView but the required
                call is nil. Please ensure that you provide a call instance in order
                to activate correctly Picture-in-Picture.
                """,
                subsystems: .pictureInPicture
            )
        }
    }
}

/// Provides the default value of the `StreamPictureInPictureAdapter` class.
enum StreamPictureInPictureAdapterKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: StreamPictureInPictureAdapter = .init()
}

extension InjectedValues {
    /// Provides access to the `StreamPictureInPictureAdapter` class to the views and view models.
    public var pictureInPictureAdapter: StreamPictureInPictureAdapter {
        get {
            Self[StreamPictureInPictureAdapterKey.self]
        }
        set {
            Self[StreamPictureInPictureAdapterKey.self] = newValue
        }
    }
}
