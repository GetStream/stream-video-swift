//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

/// The type of a call.
public struct CallType: @unchecked Sendable, Equatable {
    public let name: String
    public let sortComparators: [Comparator<CallParticipant>]
    
    public init(name: String, sortComparators: [Comparator<CallParticipant>] = CallType.defaultComparators) {
        self.name = name
        self.sortComparators = sortComparators
    }
    
    public static func == (lhs: CallType, rhs: CallType) -> Bool {
        lhs.name == rhs.name
    }
}

extension CallType {
    
    public static let `default` = CallType(name: "default")
    public static let defaultComparators: [Comparator<CallParticipant>] = [
        screensharing, dominantSpeaker, publishingVideo, publishingAudio, userId
    ]
}
