//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct SessionInfo: Sendable {
    public var call: CallData
    public var callCid: String
    public var createdAt: Date
    public var sessionId: String
}
