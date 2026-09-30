//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Runs ringing recovery actions serially when ring events are lost.
final class RingingCallRecoveryAdapter: @unchecked Sendable {

    /// Serializes fetches so responses cannot arrive out of order.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    /// Subscriptions alone do not keep policies alive.
    private let policies: [RingingRecoveryPolicy]
    private let disposableBag = DisposableBag()

    convenience init(_ streamVideo: StreamVideo) {
        var policies: [RingingRecoveryPolicy] = [
            ReconnectRingingRecoveryPolicy(streamVideo)
        ]
        if let options = streamVideo.videoConfig.ringStatePolling {
            policies.append(
                PollingRingingRecoveryPolicy(streamVideo, options: options)
            )
        }
        self.init(streamVideo, policies: policies)
    }

    init(_ streamVideo: StreamVideo, policies: [RingingRecoveryPolicy]) {
        self.policies = policies
        streamVideo.state.$ringingCall
            .dropFirst()
            .filter { $0 == nil }
            // Cancel now so an old ring cannot cancel a new ring's work.
            .sink { [weak processingQueue] _ in
                processingQueue?.cancelAllOperations()
            }
            .store(in: disposableBag)
        Publishers
            .MergeMany(policies.map(\.actionPublisher))
            // Serialize reconnect and polling fetches without deduplicating.
            .sinkTask(queue: processingQueue) { try await $0() }
            .store(in: disposableBag)
    }
}
