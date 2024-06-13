//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class DefaultParticipantAutoLeavePolicy: ParticipantAutoLeavePolicy {
    public var onPolicyTriggered: (() -> Void)?

    public init() {}
}
