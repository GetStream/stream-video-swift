//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ListDevicesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: ListDevicesResponse, rhs: ListDevicesResponse) -> Bool {
        lhs.devices == rhs.devices &&
            lhs.duration == rhs.duration
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(devices)
        hasher.combine(duration)
    }
}
