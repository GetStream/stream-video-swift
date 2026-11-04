//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IndividualRecordingResponse: @unchecked Sendable, Decodable {
    public var status: String

    public init(status: String) {
        self.status = status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.status = try container.decode(String.self, forKey: .status)
    }
}

extension IndividualRecordingResponse: Hashable {
    public static func == (lhs: IndividualRecordingResponse, rhs: IndividualRecordingResponse) -> Bool {
        lhs.status == rhs.status
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(status)
    }
}
