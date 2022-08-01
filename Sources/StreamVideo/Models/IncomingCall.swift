//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

public struct IncomingCall: Identifiable {
    public let id: String
    public let callerId: String
    
    public init(id: String, callerId: String) {
        self.id = id
        self.callerId = callerId
    }
}
