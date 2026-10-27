//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressVideoEncodingOptionsRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var layers: [IngressVideoLayerRequest]
    public var source: IngressSourceRequest

    public init(layers: [IngressVideoLayerRequest], source: IngressSourceRequest) {
        self.layers = layers
        self.source = source
    }

    public enum CodingKeys: String, CodingKey {
        case layers
        case source
    }
}

extension IngressVideoEncodingOptionsRequest: Hashable {
    public static func == (lhs: IngressVideoEncodingOptionsRequest, rhs: IngressVideoEncodingOptionsRequest) -> Bool {
        lhs.layers == rhs.layers &&
            lhs.source == rhs.source
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(layers)
        hasher.combine(source)
    }
}
