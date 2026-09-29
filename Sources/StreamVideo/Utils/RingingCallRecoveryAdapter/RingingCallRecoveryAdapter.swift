//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Keeps the ringing call's state current when ring events are lost.
///
/// Accept, reject, and end for a ring arrive as coordinator events. If one
/// is lost, `Call.state` stays stale and the caller never joins. Each
/// ``RingingRecoveryPolicy`` decides when to refresh the call; the adapter
/// runs their actions on one serial queue, so refreshes never overlap.
/// SwiftUI turns the refreshed session into the same events it already
/// handles from the socket.
final class RingingCallRecoveryAdapter: @unchecked Sendable {

    /// Runs one action at a time. Two refreshes that overlap can finish out
    /// of order, and the older one would then overwrite the newer state.
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    /// Held here because subscribing to a policy's publisher does not keep
    /// the policy alive.
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
            // Cancel synchronously: delaying this until the main queue could
            // cancel work for a new ring that has already started.
            .sink { [weak processingQueue] _ in
                processingQueue?.cancelAllOperations()
            }
            .store(in: disposableBag)
        Publishers
            .MergeMany(policies.map(\.actionPublisher))
            // Each action becomes an operation on the serial queue, so the
            // next one starts only after the previous one finishes.
            .sinkTask(queue: processingQueue) { try await $0() }
            .store(in: disposableBag)
    }
}
