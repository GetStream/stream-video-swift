//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallUpdatedEvent: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable, WSCallEvent {
    
    public var call: CallResponse
    public var callCid: String
    public var capabilitiesByRole: [String: [String]]
    public var createdAt: Date
    public var type: String

    public init(call: CallResponse, callCid: String, capabilitiesByRole: [String: [String]], createdAt: Date, type: String) {
        self.call = call
        self.callCid = callCid
        self.capabilitiesByRole = capabilitiesByRole
        self.createdAt = createdAt
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case callCid = "call_cid"
        case capabilitiesByRole = "capabilities_by_role"
        case createdAt = "created_at"
        case type
    }
}
