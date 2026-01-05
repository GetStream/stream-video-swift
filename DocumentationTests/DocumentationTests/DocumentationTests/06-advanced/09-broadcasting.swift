//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        let call = streamVideo.call(callType: .default, callId: callId)
        Task {
            try await call.join()
        }
    }

    asyncContainer {
        let call = try await call.create(members: members, custom: [:], startsAt: Date(), ring: false)
    }

    asyncContainer {
        try await call.startHLS()
    }

    asyncContainer {
        for await event in call.subscribe() {
            switch event {
            case .typeCallHLSBroadcastingStartedEvent(let broadcastingStartedEvent):
                log.debug("received an event \(broadcastingStartedEvent)")
            /* handle recording event */
            case .typeCallHLSBroadcastingStoppedEvent(let broadcastingStoppedEvent):
                log.debug("received an event \(broadcastingStoppedEvent)")
            /* handle recording event */
            default:
                break
            }
        }
    }
}
