//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// An adapter responsible for managing WebRTC subscription updates.
///
/// This class listens to participants and incoming video quality settings,
/// computes the necessary subscription details, and instructs the SFUAdapter
/// to update subscriptions accordingly. It ensures updates are sent only
/// when there are meaningful changes.
///
/// Subscription behavior is influenced by the provided `clientCapabilities`,
/// allowing customization such as support for paused tracks.
final class WebRTCUpdateSubscriptionsAdapter: @unchecked Sendable {
    /// The session identifier for the current WebRTC session.
    private let sessionID: String
    /// The adapter used to communicate with the SFU for updates.
    private let sfuAdapter: SFUAdapter
    /// A serial queue used to process update tasks in order.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    /// A factory that builds subscription details for WebRTC tracks.
    private let tracksFactory: WebRTCJoinRequestFactory
    /// Combined participants and quality-settings updates.
    private let publisher: AnyPublisher<(WebRTCStateAdapter.ParticipantsStorage, IncomingVideoQualitySettings), Never>
    /// The active subscription observing ``publisher``.
    private var publisherCancellable: AnyCancellable?

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
    ///   - clientCapabilities: A set of client capabilities affecting
    ///     subscription behavior (e.g., paused tracks support).
    init(
        participantsPublisher: AnyPublisher<
            WebRTCStateAdapter.ParticipantsStorage, Never
        >,
        incomingVideoQualitySettingsPublisher: AnyPublisher<
            IncomingVideoQualitySettings, Never
        >,
        sfuAdapter: SFUAdapter,
        sessionID: String,
        clientCapabilities: Set<ClientCapability>
    ) {
        self.sessionID = sessionID
        self.sfuAdapter = sfuAdapter
        self.publisher = Publishers.CombineLatest(
            participantsPublisher,
            incomingVideoQualitySettingsPublisher
        )
        .eraseToAnyPublisher()
        tracksFactory = .init(capabilities: clientCapabilities.map(\.rawValue))
    }

    deinit {
        processingQueue.cancelAllOperations()
    }

    // MARK: - Observation

    /// Starts observing participant and quality updates.
    ///
    /// Calling this method multiple times cancels any previous observation and
    /// restarts from the latest values.
    func startObservation() {
        processingQueue.addOperation { [weak self] in
            guard let self else { return }
            publisherCancellable?.cancel()
            publisherCancellable = nil
            publisherCancellable = publisher
                .sinkTask(queue: processingQueue) { [weak self] in
                    try await self?.process(
                        participants: $0.0,
                        incomingVideoQualitySettings: $0.1
                    )
                }
        }
    }

    /// Stops observing participant and quality updates.
    func stopObservation() {
        publisherCancellable?.cancel()
        publisherCancellable = nil
    }

    // MARK: - Specific participants subscriptions update

    /// Updates subscriptions for an explicit participants list.
    ///
    /// - Parameters:
    ///   - participants: Participants to evaluate for subscriptions.
    ///   - incomingVideoQualitySettings: The currently active quality settings.
    ///   - trackTypes: Track types to include in the update request.
    func updateSubscriptions(
        for participants: [CallParticipant],
        incomingVideoQualitySettings: IncomingVideoQualitySettings,
        trackTypes: Set<Stream_Video_Sfu_Models_TrackType>
    ) {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else {
                return
            }
            let tracks = tracksFactory.buildSubscriptionDetails(
                nil,
                sessionID: sessionID,
                participants: participants,
                incomingVideoQualitySettings: incomingVideoQualitySettings
            )
            .filter { trackTypes.contains($0.trackType) }

            try await executeSubscriptionsUpdate(for: tracks)
        }
    }

    // MARK: - Private Helpers

    private func process(
        participants: WebRTCStateAdapter.ParticipantsStorage,
        incomingVideoQualitySettings: IncomingVideoQualitySettings,
        trackTypes: Set<Stream_Video_Sfu_Models_TrackType> = [.video, .screenShare, .screenShareAudio]
    ) async throws {
        let tracks = tracksFactory.buildSubscriptionDetails(
            nil,
            sessionID: sessionID,
            participants: Array(participants.values),
            incomingVideoQualitySettings: incomingVideoQualitySettings
        )
        .filter { trackTypes.contains($0.trackType) }

        try await executeSubscriptionsUpdate(for: tracks)
    }

    private func executeSubscriptionsUpdate(
        for tracks: [Stream_Video_Sfu_Signal_TrackSubscriptionDetails]
    ) async throws {
        let setTracks = Set(tracks)
        let setLastTrackSubscriptionDetails =
            Set(lastTrackSubscriptionDetails)

        guard setTracks != setLastTrackSubscriptionDetails else {
            return
        }

        try Task.checkCancellation()

        try await sfuAdapter.updateSubscriptions(
            tracks: tracks,
            for: sessionID
        )

        lastTrackSubscriptionDetails = tracks
    }
}
