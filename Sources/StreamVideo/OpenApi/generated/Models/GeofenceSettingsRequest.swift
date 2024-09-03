//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GeofenceSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var names: [String]? = nil

    public init(names: [String]? = nil) {
        self.names = names
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case names
    }
}
