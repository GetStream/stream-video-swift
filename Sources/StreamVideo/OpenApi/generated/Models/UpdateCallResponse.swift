//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

/** Represents a call */
internal struct UpdateCallResponse: Codable, JSONEncodable, Hashable {

    internal var call: CallResponse
    internal var duration: String

    internal init(call: CallResponse, duration: String) {
        self.call = call
        self.duration = duration
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case call
        case duration
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(call, forKey: .call)
        try container.encode(duration, forKey: .duration)
    }
}
