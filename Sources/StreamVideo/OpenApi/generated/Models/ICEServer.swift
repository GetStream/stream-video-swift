//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct ICEServer: Codable, JSONEncodable, Hashable {

    internal var password: String
    internal var urls: [String]
    internal var username: String

    internal init(password: String, urls: [String], username: String) {
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
        try container.encode(password, forKey: .password)
        try container.encode(urls, forKey: .urls)
        try container.encode(username, forKey: .username)
    }
}
