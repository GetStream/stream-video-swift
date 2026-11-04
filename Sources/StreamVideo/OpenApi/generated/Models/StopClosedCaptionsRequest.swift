//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class StopClosedCaptionsRequest: @unchecked Sendable, Encodable, JSONEncodable {
    public var stopTranscription: Bool?

    public init(stopTranscription: Bool? = nil) {
        self.stopTranscription = stopTranscription
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
