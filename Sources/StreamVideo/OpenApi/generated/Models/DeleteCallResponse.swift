//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct DeleteCallResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var duration: String
    public var taskId: String? = nil

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
}
