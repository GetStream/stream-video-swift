//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class NoiseCancellationSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum Mode: String, Sendable, Codable, CaseIterable {
        case autoOn = "auto-on"
        case available
        case disabled
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
               let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    
    public var mode: Mode

    public init(mode: Mode) {
        self.mode = mode
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
    }
    
    public static func == (lhs: NoiseCancellationSettingsRequest, rhs: NoiseCancellationSettingsRequest) -> Bool {
        lhs.mode == rhs.mode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
    }
}
