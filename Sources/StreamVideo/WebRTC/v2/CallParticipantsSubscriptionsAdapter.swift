//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class CallParticipantsSubscriptionsAdapter {

    private let sfuAdapter: SFUAdapter
    private var cancellable: AnyCancellable?
    private var activeTask: Task<Void, Never>?

    init(
        sfuAdapter: SFUAdapter,
        participantsPublisher: AnyPublisher<[CallParticipant], Never>
    ) {
        self.sfuAdapter = sfuAdapter
        cancellable = participantsPublisher
            .receive(on: DispatchQueue.global(qos: .utility))
            .removeDuplicates()
            .sink { [weak self] in self?.didUpdate($0) }
    }

    deinit {
        cancellable?.cancel()
        activeTask?.cancel()
        activeTask = nil
    }

    private func didUpdate(_ participants: [CallParticipant]) {
        let subscriptions = participants.flatMap(\.trackSubscriptionDetails)
        activeTask?.cancel()
        activeTask = Task { [sfuAdapter] in
            do {
                try await sfuAdapter.updateSubscriptions(tracks: subscriptions, for: nil)
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
    }
}
