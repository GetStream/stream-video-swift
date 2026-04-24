//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A policy that decides whether the local user should
/// automatically leave a call based on participant state.
///
/// Both ``CallViewModel`` and ``CallKitService`` accept a
/// policy instance and wire `onPolicyTriggered` internally.
/// Because the protocol exposes a **single** closure slot,
/// each consumer **must** receive its own policy instance.
/// Sharing one instance between two consumers will cause the
/// later assignment to silently disconnect the earlier one.
public protocol ParticipantAutoLeavePolicy: Sendable {

    /// Called by the policy implementation when its rules are
    /// satisfied (e.g. only one participant remains).
    ///
    /// - Important: Only one consumer should set this closure
    ///   per policy instance. Create a dedicated instance for
    ///   each consumer (``CallViewModel``, ``CallKitService``,
    ///   etc.) to avoid overwriting another consumer's handler.
    var onPolicyTriggered: (() -> Void)? { get set }
}
