//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StopClosedCaptionsRequest: @unchecked Sendable, Encodable, JSONEncodable, Hashable {
    
    public var stopTranscription: Bool?

    public init(stopTranscription: Bool? = nil) {
        self.stopTranscription = stopTranscription
    }
    
    public enum CodingKeys: String, CodingKey {
        case stopTranscription = "stop_transcription"
    }
    
    public static func == (lhs: StopClosedCaptionsRequest, rhs: StopClosedCaptionsRequest) -> Bool {
        lhs.stopTranscription == rhs.stopTranscription
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(stopTranscription)
    }
}
