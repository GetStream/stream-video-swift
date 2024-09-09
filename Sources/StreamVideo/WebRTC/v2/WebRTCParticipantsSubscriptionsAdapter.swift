//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A class that when remote CallParticipants get updated, informs the SFU for their changes.
final class WebRTCParticipantsSubscriptionsAdapter {
    /// The sessionId for which the adapter will report updated subscriptions.
    private let sessionId: String

    /// The SFU adapter used for updating subscriptions.
    private let sfuAdapter: SFUAdapter

    /// A cancellable object for managing the subscription to the participants publisher.
    private var cancellable: AnyCancellable?

    /// The currently active task for updating subscriptions.
    private var activeTask: Task<Void, Never>?

    /// Initializes a new instance of the CallParticipantsSubscriptionsAdapter.
    ///
    /// - Parameters:
    ///   - sessionId: The ID of the current session.
    ///   - sfuAdapter: The SFU adapter to use for updating subscriptions.
    ///   - participantsPublisher: A publisher that emits arrays of CallParticipant objects.
    init(
        sessionId: String,
        sfuAdapter: SFUAdapter,
        participantsPublisher: AnyPublisher<[CallParticipant], Never>
    ) {
        self.sessionId = sessionId
        self.sfuAdapter = sfuAdapter
        cancellable = participantsPublisher
            .receive(on: DispatchQueue.global(qos: .utility))
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdate($0) }
    }

    /// Cleans up resources when the instance is deinitialized.
    deinit {
        cancellable?.cancel()
        activeTask?.cancel()
        activeTask = nil
    }

    /// Updates the subscriptions based on the provided participants.
    ///
    /// - Parameter participants: An array of CallParticipant objects.
    private func didUpdate(_ participants: [CallParticipant]) {
        let subscriptions = participants.flatMap(\.trackSubscriptionDetails)
        activeTask?.cancel()
        activeTask = Task { [sfuAdapter, sessionId] in
            do {
                try await sfuAdapter.updateSubscriptions(
                    tracks: subscriptions,
                    for: sessionId
                )
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
    }
}
