//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StopClosedCaptionsRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var stopTranscription: Bool?

    public init(stopTranscription: Bool? = nil) {
        self.stopTranscription = stopTranscription
    }

    public enum CodingKeys: String, CodingKey {
        case stopTranscription = "stop_transcription"
    }
}

extension StopClosedCaptionsRequest: Hashable {
    public static func == (lhs: StopClosedCaptionsRequest, rhs: StopClosedCaptionsRequest) -> Bool {
        lhs.stopTranscription == rhs.stopTranscription
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stopTranscription)
    }
}
