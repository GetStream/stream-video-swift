//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class StopTranscriptionRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public init() {}
    
    public static func == (lhs: StopTranscriptionRequest, rhs: StopTranscriptionRequest) -> Bool {}

    public func hash(into hasher: inout Hasher) {}
}
