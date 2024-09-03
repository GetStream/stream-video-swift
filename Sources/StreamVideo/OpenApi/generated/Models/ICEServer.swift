//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ICEServer: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var password: String
    public var urls: [String]
    public var username: String

    public init(password: String, urls: [String], username: String) {
        self.password = password
        self.urls = urls
        self.username = username
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case password
        case urls
        case username
    }
}
