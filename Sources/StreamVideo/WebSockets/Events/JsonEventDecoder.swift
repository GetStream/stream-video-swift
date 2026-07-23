//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

struct JsonEventDecoder: AnyEventDecoder {
    func decode(from data: Data) throws -> StreamCore.Event {
        let event = try JSONDecoder.streamCore.decode(VideoEvent.self, from: data)
        return WrappedEvent.coordinatorEvent(event)
    }
}

extension VideoEvent: @unchecked Sendable, Event {}

extension UserResponse {
    public var toUser: User {
        User(
            id: id,
            name: name,
            imageURL: URL(string: image ?? ""),
            role: role,
            customData: custom
        )
    }
}
