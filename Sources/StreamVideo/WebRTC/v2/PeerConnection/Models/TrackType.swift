//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct TrackType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }

    init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension TrackType {
    static let audio: Self = "audio"
    static let video: Self = "video"
    static let screenShare: Self = "screenshare"
    static let unknown: Self = "unknown"
}
