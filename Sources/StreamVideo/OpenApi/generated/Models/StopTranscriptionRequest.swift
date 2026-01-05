//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StopTranscriptionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var stopClosedCaptions: Bool?

    public init(stopClosedCaptions: Bool? = nil) {
        self.stopClosedCaptions = stopClosedCaptions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case stopClosedCaptions = "stop_closed_captions"
    }
    
    public static func == (lhs: StopTranscriptionRequest, rhs: StopTranscriptionRequest) -> Bool {
        lhs.stopClosedCaptions == rhs.stopClosedCaptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stopClosedCaptions)
    }
}
