//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class LayoutSettingsName: RawRepresentable, Codable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let custom = LayoutSettingsName(rawValue: "custom")
    public static let grid = LayoutSettingsName(rawValue: "grid")
    public static let mobile = LayoutSettingsName(rawValue: "mobile")
    public static let singleParticipant = LayoutSettingsName(rawValue: "single-participant")
    public static let spotlight = LayoutSettingsName(rawValue: "spotlight")
}

public final class LayoutSettings: @unchecked Sendable, Encodable, JSONEncodable {
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
