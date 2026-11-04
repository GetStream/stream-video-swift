//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressVideoEncodingResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var layers: [IngressVideoLayerResponse]
    public var source: IngressSourceResponse

    public init(layers: [IngressVideoLayerResponse], source: IngressSourceResponse) {
        self.layers = layers
        self.source = source
    }

    public enum CodingKeys: String, CodingKey {
        case layers
        case source
    }
}

extension IngressVideoEncodingResponse: Hashable {
    public static func == (lhs: IngressVideoEncodingResponse, rhs: IngressVideoEncodingResponse) -> Bool {
        lhs.layers == rhs.layers &&
            lhs.source == rhs.source
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(layers)
        hasher.combine(source)
    }
}
