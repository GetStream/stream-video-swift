//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class LayoutSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum Name: String, Sendable, Codable, CaseIterable {
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
    public var name: Name
    public var options: [String: RawJSON]?

    public init(
        detectOrientation: Bool? = nil,
        externalAppUrl: String? = nil,
        externalCssUrl: String? = nil,
        name: Name,
        options: [String: RawJSON]? = nil
    ) {
        self.detectOrientation = detectOrientation
        self.externalAppUrl = externalAppUrl
        self.externalCssUrl = externalCssUrl
        self.name = name
        self.options = options
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case detectOrientation = "detect_orientation"
        case externalAppUrl = "external_app_url"
        case externalCssUrl = "external_css_url"
        case name
        case options
    }
    
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
