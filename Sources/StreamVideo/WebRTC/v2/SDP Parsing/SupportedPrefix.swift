//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum SupportedPrefix: String, Hashable, CaseIterable {
    case unsupported
    case rtmap = "a=rtpmap:"

    static func isPrefixSupported(for line: String) -> SupportedPrefix {
        guard
            let supportedPrefix = SupportedPrefix
            .allCases
            .first(where: { $0 != .unsupported && line.hasPrefix($0.rawValue) })
        else {
            return .unsupported
        }

        return supportedPrefix
    }
}
