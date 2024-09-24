import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine

@MainActor
fileprivate func content() {
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
