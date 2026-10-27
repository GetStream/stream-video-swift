//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CompositeRecordingResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var status: String

    public init(status: String) {
        self.status = status
    }

    public enum CodingKeys: String, CodingKey {
        case status
    }
}

extension CompositeRecordingResponse: Hashable {
    public static func == (lhs: CompositeRecordingResponse, rhs: CompositeRecordingResponse) -> Bool {
        lhs.status == rhs.status
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(status)
    }
}
