//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

indirect enum RTCAudioStoreAction: Sendable {
    case generic(RTCAudioStoreAction.Generic)

    case audioSession(RTCAudioStoreAction.AudioSession)

    case callKit(RTCAudioStoreAction.CallKit)

    case failable(RTCAudioStoreAction)
}
