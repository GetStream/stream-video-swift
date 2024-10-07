//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StopRecordingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }
    
    public static func == (lhs: StopRecordingResponse, rhs: StopRecordingResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
