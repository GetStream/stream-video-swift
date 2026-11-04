//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class LayoutSettings: @unchecked Sendable, Encodable, JSONEncodable {
    
    public enum LayoutSettingsName: String, Sendable, Codable, CaseIterable {
        case custom
        case grid
        case mobile
        case singleParticipant = "single-participant"
        case spotlight
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

    public var detectOrientation: Bool?
    public var externalAppUrl: String?
    public var externalCssUrl: String?
    public var name: LayoutSettingsName
    public var options: [String: RawJSON]?

    public init(
        detectOrientation: Bool? = nil,
        externalAppUrl: String? = nil,
        externalCssUrl: String? = nil,
        name: LayoutSettingsName,
        options: [String: RawJSON]? = nil
    ) {
        self.detectOrientation = detectOrientation
        self.externalAppUrl = externalAppUrl
        self.externalCssUrl = externalCssUrl
        self.name = name
        self.options = options
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(detectOrientation, forKey: .detectOrientation)
        try container.encodeIfPresent(externalAppUrl, forKey: .externalAppUrl)
        try container.encodeIfPresent(externalCssUrl, forKey: .externalCssUrl)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(options, forKey: .options)
    }
}

extension LayoutSettings: Hashable {
    public static func == (lhs: LayoutSettings, rhs: LayoutSettings) -> Bool {
        lhs.detectOrientation == rhs.detectOrientation &&
            lhs.externalAppUrl == rhs.externalAppUrl &&
            lhs.externalCssUrl == rhs.externalCssUrl &&
            lhs.name == rhs.name &&
            lhs.options == rhs.options
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(detectOrientation)
        hasher.combine(externalAppUrl)
        hasher.combine(externalCssUrl)
        hasher.combine(name)
        hasher.combine(options)
    }
}
