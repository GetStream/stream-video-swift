//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct WSAuthMessageRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var products: [String]? = nil
    public var token: String
    public var userDetails: ConnectUserDetailsRequest

    public init(products: [String]? = nil, token: String, userDetails: ConnectUserDetailsRequest) {
        self.products = products
        self.token = token
        self.userDetails = userDetails
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case products
        case token
        case userDetails = "user_details"
    }
}
