//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

public final class DeleteRecordingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var duration: String

    public init(duration: String) {
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }
    
    public static func == (lhs: DeleteRecordingResponse, rhs: DeleteRecordingResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
