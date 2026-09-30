//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// An asynchronous ringing-call refresh.
typealias RingingRecoveryAction = @Sendable () async throws -> Void

/// Decides when and how to refresh a ringing call.
protocol RingingRecoveryPolicy {
    /// Refreshes requested by this policy.
    var actionPublisher: AnyPublisher<RingingRecoveryAction, Never> { get }
}
