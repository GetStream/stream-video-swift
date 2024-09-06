//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct TURNAggregatedStats: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var tcp: Count?
    public var total: Count?

    public init(tcp: Count? = nil, total: Count? = nil) {
        self.tcp = tcp
        self.total = total
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case tcp
        case total
    }
}
