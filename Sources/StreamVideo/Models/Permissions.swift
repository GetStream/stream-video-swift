//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct Permission: Sendable, RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension Permission {
    static let sendAudio: Self = "send-audio"
    static let sendVideo: Self = "send-video"
    static let screenshare: Self = "screenshare"
}
