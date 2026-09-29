//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Refreshes the ringing call from the coordinator.
typealias RingingRecoveryAction = @Sendable () async throws -> Void

/// Decides when the ringing call needs a refresh and how to fetch it.
///
/// Ring outcomes (accept, reject, end) reach the client only over the
/// WebSocket and are not resent. A policy watches for a case where one may
/// have been lost and emits an action that brings `Call.state` up to date.
/// ``RingingCallRecoveryAdapter`` runs the actions of all policies one at a
/// time, so two refreshes never overlap.
protocol RingingRecoveryPolicy {
    /// Emits an action every time the policy wants the ringing call
    /// refreshed.
    var actionPublisher: AnyPublisher<RingingRecoveryAction, Never> { get }
}
