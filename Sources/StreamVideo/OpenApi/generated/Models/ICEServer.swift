//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ICEServer: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: ICEServer, rhs: ICEServer) -> Bool {
        lhs.password == rhs.password &&
            lhs.urls == rhs.urls &&
            lhs.username == rhs.username
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(password)
        hasher.combine(urls)
        hasher.combine(username)
    }
}
