//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

/// The type of a call.
public struct CallType: Sendable, Equatable {
    public let name: String
    
    public init(name: String) {
        self.name = name
    }
}

extension CallType {
    
    public static let `default` = CallType(name: "default")
}
