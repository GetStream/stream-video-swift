//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// DeleteCallResponse is the payload for deleting a call.
public final class DeleteCallResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// Represents a call
    public var call: CallResponse
    public var duration: String
    public var taskId: String?

    public init(call: CallResponse, duration: String, taskId: String? = nil) {
        self.call = call
        self.duration = duration
        self.taskId = taskId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.call = try container.decode(CallResponse.self, forKey: .call)
        self.duration = try container.decode(String.self, forKey: .duration)
        self.taskId = try container.decodeIfPresent(String.self, forKey: .taskId)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(call, forKey: .call)
        try container.encode(duration, forKey: .duration)
        try container.encodeIfPresent(taskId, forKey: .taskId)
    }
}

extension DeleteCallResponse: Hashable {
    public static func == (lhs: DeleteCallResponse, rhs: DeleteCallResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.duration == rhs.duration &&
            lhs.taskId == rhs.taskId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(duration)
        hasher.combine(taskId)
    }
}
