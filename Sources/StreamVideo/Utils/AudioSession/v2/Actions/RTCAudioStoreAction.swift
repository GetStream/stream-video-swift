//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

enum RTCAudioStoreAction: Sendable {
    case store(RTCAudioStore.Action)

    case rtc(RTCAudioSessionReducer.Action)

    case callKit(CallKitAudioSessionReducer.Action)
}
