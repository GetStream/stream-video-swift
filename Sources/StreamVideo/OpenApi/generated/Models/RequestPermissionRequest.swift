//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct RequestPermissionRequest: Codable, JSONEncodable, Hashable {

    internal enum Permissions: String, Codable, CaseIterable {
        case screenshare
        case sendAudio = "send-audio"
        case sendVideo = "send-video"
    }

    internal var permissions: Permissions

    internal init(permissions: Permissions) {
        self.permissions = permissions
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case permissions
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(permissions, forKey: .permissions)
    }
}
