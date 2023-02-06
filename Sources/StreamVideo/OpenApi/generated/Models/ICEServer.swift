//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct ICEServer: Codable, JSONEncodable, Hashable {

    internal var password: String?
    internal var urls: [String]?
    internal var username: String?

    internal init(password: String? = nil, urls: [String]? = nil, username: String? = nil) {
        self.password = password
        self.urls = urls
        self.username = username
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case password
        case urls
        case username
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(password, forKey: .password)
        try container.encodeIfPresent(urls, forKey: .urls)
        try container.encodeIfPresent(username, forKey: .username)
    }
}
