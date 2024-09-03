//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct ListDevicesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var devices: [Device]
    public var duration: String

    public init(devices: [Device], duration: String) {
        self.devices = devices
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case devices
        case duration
    }
}
