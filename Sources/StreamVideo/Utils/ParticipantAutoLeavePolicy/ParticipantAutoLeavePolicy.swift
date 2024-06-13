//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ParticipantAutoLeavePolicy {
    var onPolicyTriggered: (() -> Void)? { get set }
}
