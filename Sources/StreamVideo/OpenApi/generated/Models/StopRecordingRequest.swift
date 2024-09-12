//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class StopRecordingRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public init() {}
    
    public static func == (lhs: StopRecordingRequest, rhs: StopRecordingRequest) -> Bool {}

    public func hash(into hasher: inout Hasher) {}
}
