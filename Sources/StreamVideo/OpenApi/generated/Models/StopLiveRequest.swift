//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class StopLiveRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public init() {}
    
    public static func == (lhs: StopLiveRequest, rhs: StopLiveRequest) -> Bool {}

    public func hash(into hasher: inout Hasher) {}
}
