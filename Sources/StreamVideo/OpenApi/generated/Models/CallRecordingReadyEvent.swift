//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallRecordingReadyEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var callCid: String
    public var callRecording: CallRecording
    public var createdAt: Date
    public var type: String

    public init(callCid: String, callRecording: CallRecording, createdAt: Date, type: String) {
        self.callCid = callCid
        self.callRecording = callRecording
        self.createdAt = createdAt
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case callCid = "call_cid"
        case callRecording = "call_recording"
        case createdAt = "created_at"
        case type
    }
}
