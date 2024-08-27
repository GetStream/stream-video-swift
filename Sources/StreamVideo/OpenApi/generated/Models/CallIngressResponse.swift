//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallIngressResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var rtmp: RTMPIngress

    public init(rtmp: RTMPIngress) {
        self.rtmp = rtmp
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rtmp
    }
}
