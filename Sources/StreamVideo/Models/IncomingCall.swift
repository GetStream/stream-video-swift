//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct IncomingCall: Identifiable {
    public let id: String
    public let callerId: String
    public let type: String
    
    public init(id: String, callerId: String, type: String) {
        self.id = id
        self.callerId = callerId
        self.type = type
    }
}
