//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct VideoWSAuthMessageRequest: Codable, JSONEncodable, Hashable {

    internal var device: DeviceFieldsRequest?
    /** Token string */
    internal var token: String
    internal var userDetails: UserObjectRequest

    internal init(device: DeviceFieldsRequest? = nil, token: String, userDetails: UserObjectRequest) {
        self.device = device
        self.token = token
        self.userDetails = userDetails
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case device
        case token
        case userDetails = "user_details"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(device, forKey: .device)
        try container.encode(token, forKey: .token)
        try container.encode(userDetails, forKey: .userDetails)
    }
}
