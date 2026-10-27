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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.stopTranscription = try container.decodeIfPresent(Bool.self, forKey: .stopTranscription)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(stopTranscription, forKey: .stopTranscription)
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
