//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class DeleteCallResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var duration: String
    public var taskId: String?

    public init(call: CallResponse, duration: String, taskId: String? = nil) {
        self.call = call
        self.duration = duration
        self.taskId = taskId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case duration
        case taskId = "task_id"
    }
    
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
