//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A policy that can be used to apply certain business logic depending on the participants state during
/// a call.
public protocol ParticipantAutoLeavePolicy: Sendable {

    /// A closure that will be called once the rules evaluated in the policy have been triggered.
    var onPolicyTriggered: (() -> Void)? { get set }
}
