//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum WebRTCPreferredVideoResolution: Equatable, CustomStringConvertible {
    case none
    case custom(sessionIds: Set<String>, targetSize: CGSize)

    var description: String {
        switch self {
        case .none:
            return ".none"
        case let .custom(sessionIds: sessionIds, targetSize: targetSize):
            return ".custom(\(sessionIds), \(targetSize))"
        }
    }

    func contains(_ sessionId: String) -> Bool {
        switch self {
        case .none:
            return false
        case let .custom(sessionIds, _):
            return sessionIds.contains(sessionId)
        }
    }

    var targetSize: CGSize? {
        switch self {
        case .none:
            return nil
        case let .custom(_, targetSize):
            return targetSize
        }
    }

    static func == (
        lhs: WebRTCPreferredVideoResolution,
        rhs: WebRTCPreferredVideoResolution
    ) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (let .custom(lhsSessionIds, lhsTargetSize), let .custom(rhsSessionIds, rhsTargetSize)):
            return lhsSessionIds == rhsSessionIds && lhsTargetSize == rhsTargetSize
        default:
            return false
        }
    }
}

enum WebRTCDisabledIncomingVideo: Equatable, CustomStringConvertible {
    case none
    case all
    case custom(sessionIds: Set<String>)

    var description: String {
        switch self {
        case .none:
            return ".none"
        case .all:
            return ".all"
        case let .custom(sessionIds: sessionIds):
            return ".custom(\(sessionIds))"
        }
    }

    func contains(_ sessionId: String) -> Bool {
        switch self {
        case .none:
            return false
        case .all:
            return true
        case let .custom(value):
            return value.contains(sessionId)
        }
    }
}
