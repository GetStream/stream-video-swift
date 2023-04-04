//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

/// The type of a call.
public struct CallType: @unchecked Sendable, Equatable {
    /// The name of the call type.
    public let name: String
    /// An array of sort comparators used for sorting participants in the call.
    public let sortComparators: [Comparator<CallParticipant>]
    
    /// Initializes a new `CallType`.
    /// - Parameters:
    ///   - name: The name of the call type.
    ///   - sortComparators: An optional array of sort comparators used for sorting participants in the call. If not provided, the default comparators will be used.
    public init(name: String, sortComparators: [Comparator<CallParticipant>] = defaultComparators) {
        self.name = name
        self.sortComparators = sortComparators
    }
    
    /// Returns whether two `CallType` instances are equal.
    public static func == (lhs: CallType, rhs: CallType) -> Bool {
        lhs.name == rhs.name
    }
}

extension CallType {
    /// The default call type.
    public static let `default` = CallType(name: "default")
    /// The ringing call type.
    public static let ringing = CallType(name: "ringing")
    /// The development call type.
    public static let development = CallType(name: "development")
    /// The audio room call type.
    public static let audioRoom = CallType(name: "audio_room", sortComparators: livestreamComparators)
    /// The livestream call type.
    public static let livestream = CallType(name: "livestream", sortComparators: livestreamComparators)
}
