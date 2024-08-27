//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GetApplicationResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var app: AppResponseFields
    public var duration: String

    public init(app: AppResponseFields, duration: String) {
        self.app = app
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case app
        case duration
    }
}
