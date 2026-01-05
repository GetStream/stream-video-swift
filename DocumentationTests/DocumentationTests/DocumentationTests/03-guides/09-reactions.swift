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
        let response = try await call.sendReaction(type: "fireworks")
    }

    asyncContainer {
        let response = try await call.sendReaction(
            type: "raise-hand",
            custom: ["mycustomfield": "hello"],
            emojiCode: ":smile:"
        )
    }

    asyncContainer {
        let response = try await call.sendCustomEvent(["type": .string("draw"), "x": .number(10), "y": .number(20)])
    }
    
    asyncContainer {
        for await event in call.subscribe(for: CallReactionEvent.self) {
            // handle reaction event
        }
    }
}
