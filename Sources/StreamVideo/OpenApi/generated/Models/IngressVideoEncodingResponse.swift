//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressVideoEncodingResponse: Sendable, Decodable {
    public let layers: [IngressVideoLayerResponse]
    public let source: IngressSourceResponse

    public init(layers: [IngressVideoLayerResponse], source: IngressSourceResponse) {
        self.layers = layers
        self.source = source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.layers = try container.decode([IngressVideoLayerResponse].self, forKey: .layers)
        self.source = try container.decode(IngressSourceResponse.self, forKey: .source)
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
