//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A default implementation of the `ParticipantAutoLeavePolicy` protocol, that contains no
/// rules and thus the closure will never be executed.
public final class DefaultParticipantAutoLeavePolicy: ParticipantAutoLeavePolicy, @unchecked Sendable {

    public var onPolicyTriggered: (() -> Void)?

    public init() {}
}
