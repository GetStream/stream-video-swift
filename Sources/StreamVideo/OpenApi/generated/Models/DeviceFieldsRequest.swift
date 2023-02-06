//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct DeviceFieldsRequest: Codable, JSONEncodable, Hashable {

    internal enum PushProvider: String, Codable, CaseIterable {
        case firebase
        case apn
        case huawei
        case xiaomi
    }

    /** Device ID */
    internal var id: String?
    internal var pushProvider: PushProvider?
    /** Name of the push provider configuration */
    internal var pushProviderName: String?

    internal init(id: String? = nil, pushProvider: PushProvider? = nil, pushProviderName: String? = nil) {
        self.id = id
        self.pushProvider = pushProvider
        self.pushProviderName = pushProviderName
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        case pushProvider = "push_provider"
        case pushProviderName = "push_provider_name"
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(pushProvider, forKey: .pushProvider)
        try container.encodeIfPresent(pushProviderName, forKey: .pushProviderName)
    }
}
