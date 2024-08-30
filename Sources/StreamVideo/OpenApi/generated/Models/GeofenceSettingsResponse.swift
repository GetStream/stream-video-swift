//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GeofenceSettingsResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var names: [String]

    public init(names: [String]) {
        self.names = names
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case names
    }
}
