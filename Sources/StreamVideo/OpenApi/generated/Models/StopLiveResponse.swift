//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StopLiveResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: StopLiveResponse, rhs: StopLiveResponse) -> Bool {
        lhs.call == rhs.call &&
            lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(call)
        hasher.combine(duration)
    }
}
