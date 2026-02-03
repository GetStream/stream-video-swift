//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressVideoEncodingOptionsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var layers: [IngressVideoLayerRequest]
    public var source: IngressSourceRequest

    public init(layers: [IngressVideoLayerRequest], source: IngressSourceRequest) {
        self.layers = layers
        self.source = source
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case layers
        case source
    }

    public static func == (lhs: IngressVideoEncodingOptionsRequest, rhs: IngressVideoEncodingOptionsRequest) -> Bool {
        lhs.layers == rhs.layers &&
        lhs.source == rhs.source
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(layers)
        hasher.combine(source)
    }
}
