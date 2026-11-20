//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The coordinator returns an object. The SDK does not read its fields.
final class HLSStatsAcknowledgement: Decodable, Sendable {
    init(from decoder: Decoder) throws {
        _ = try decoder.container(keyedBy: StringCodingKey.self)
    }
}
