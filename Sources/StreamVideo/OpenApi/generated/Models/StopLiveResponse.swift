//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StopLiveResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Represents a call
    public var call: CallResponse
    public var duration: String

    public init(call: CallResponse, duration: String) {
        self.call = call
        self.duration = duration
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.duration = try container.decode(String.self, forKey: .duration)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(duration, forKey: .duration)
    }
}

extension StopLiveResponse: Hashable {
    public static func == (lhs: StopLiveResponse, rhs: StopLiveResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(duration)
    }
}
