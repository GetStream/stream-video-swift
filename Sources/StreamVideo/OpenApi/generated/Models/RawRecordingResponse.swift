//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RawRecordingResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var status: String

    public init(status: String) {
        self.status = status
    }

    public enum CodingKeys: String, CodingKey {
        case status
    }
}

extension RawRecordingResponse: Hashable {
    public static func == (lhs: RawRecordingResponse, rhs: RawRecordingResponse) -> Bool {
        lhs.status == rhs.status
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(status)
    }
}
