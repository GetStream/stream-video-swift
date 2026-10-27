//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StopTranscriptionRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var stopClosedCaptions: Bool?

    public init(stopClosedCaptions: Bool? = nil) {
        self.stopClosedCaptions = stopClosedCaptions
    }

    public enum CodingKeys: String, CodingKey {
        case stopClosedCaptions = "stop_closed_captions"
    }
}

extension StopTranscriptionRequest: Hashable {
    public static func == (lhs: StopTranscriptionRequest, rhs: StopTranscriptionRequest) -> Bool {
        lhs.stopClosedCaptions == rhs.stopClosedCaptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stopClosedCaptions)
    }
}
