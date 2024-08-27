//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GoLiveResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var call: CallResponse
    public var duration: String

    public init(call: CallResponse, duration: String) {
        self.call = call
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case duration
    }
}
