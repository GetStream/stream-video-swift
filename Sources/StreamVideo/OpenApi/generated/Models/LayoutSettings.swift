//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct LayoutSettings: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum Name: String, Codable, CaseIterable {
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
    
    public var externalAppUrl: String? = nil
    public var externalCssUrl: String? = nil
    public var name: Name
    public var options: [String: RawJSON]? = nil

    public init(externalAppUrl: String? = nil, externalCssUrl: String? = nil, name: Name, options: [String: RawJSON]? = nil) {
        self.externalAppUrl = externalAppUrl
        self.externalCssUrl = externalCssUrl
        self.name = name
        self.options = options
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case externalAppUrl = "external_app_url"
        case externalCssUrl = "external_css_url"
        case name
        case options
    }
}
