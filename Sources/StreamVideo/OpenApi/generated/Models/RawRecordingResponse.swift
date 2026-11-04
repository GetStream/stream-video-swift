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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.status = try container.decode(String.self, forKey: .status)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(status, forKey: .status)
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
