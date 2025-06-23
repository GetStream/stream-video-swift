//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// An adapter responsible for managing WebRTC subscription updates.
///
/// This class listens to participants and incoming video quality settings,
/// computes the necessary subscription details, and instructs the SFUAdapter
/// to update subscriptions accordingly. It ensures updates are sent only
/// when there are meaningful changes.
final class WebRTCUpdateSubscriptionsAdapter: @unchecked Sendable {
    /// The session identifier for the current WebRTC session.
    private let sessionID: String
    /// The adapter used to communicate with the SFU for updates.
    private let sfuAdapter: SFUAdapter
    /// A serial queue used to process update tasks in order.
    private let processingQueue = OperationQueue()
    /// A factory that builds subscription details for WebRTC tracks.
    private let tracksFactory: WebRTCJoinRequestFactory = .init()
    /// A container for cancellable Combine subscriptions.
    private let disposableBag = DisposableBag()
    /// The active Combine subscription observing participants and settings.
    private var observable: AnyCancellable?

    /// Stores the last set of track subscription details sent to the SFU.
    private var lastTrackSubscriptionDetails:
        [Stream_Video_Sfu_Signal_TrackSubscriptionDetails] = []

    /// Initializes the adapter with publishers and required dependencies.
    ///
    /// - Parameters:
    ///   - participantsPublisher: A publisher emitting current participants.
    ///   - incomingVideoQualitySettingsPublisher: A publisher emitting
    ///     video quality settings.
    ///   - sfuAdapter: The SFU adapter to send updates to.
    ///   - sessionID: The identifier for the session.
    init(
        participantsPublisher: AnyPublisher<
            WebRTCStateAdapter.ParticipantsStorage, Never
        >,
        incomingVideoQualitySettingsPublisher: AnyPublisher<
            IncomingVideoQualitySettings, Never
        >,
        sfuAdapter: SFUAdapter,
        sessionID: String
    ) {
        self.sessionID = sessionID
        self.sfuAdapter = sfuAdapter
        observable = Publishers.CombineLatest(
            participantsPublisher,
            incomingVideoQualitySettingsPublisher
        )
        .sink { [weak self] in self?.didUpdate(
            participants: $0,
            incomingVideoQualitySettings: $1
        ) }
    }

    deinit {
        processingQueue.cancelAllOperations()
    }

    // MARK: - Private Helpers

    /// Handles updates when participants or quality settings change.
    ///
    /// This function builds the new subscription details, compares them to
    /// the last known state, and triggers an update if they differ.
    ///
    /// - Parameters:
    ///   - participants: The current storage of participants.
    ///   - incomingVideoQualitySettings: The current video quality settings.
    private func didUpdate(
        participants: WebRTCStateAdapter.ParticipantsStorage,
        incomingVideoQualitySettings: IncomingVideoQualitySettings
    ) {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }

            let tracks = tracksFactory.buildSubscriptionDetails(
                nil,
                sessionID: sessionID,
                participants: Array(participants.values),
                incomingVideoQualitySettings: incomingVideoQualitySettings
            )
            .filter { $0.trackType != .audio }

            let setTracks = Set(tracks)
            let setLastTrackSubscriptionDetails =
                Set(lastTrackSubscriptionDetails)

            guard setTracks != setLastTrackSubscriptionDetails else {
                return
            }

            do {
                try Task.checkCancellation()
                try await sfuAdapter.updateSubscriptions(
                    tracks: tracks,
                    for: sessionID
                )
                lastTrackSubscriptionDetails = tracks
            } catch {
                log.warning(
                    "UpdateSubscriptions failed with error:\(error).",
                    subsystems: .webRTC
                )
            }
        }
    }
}
