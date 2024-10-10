//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

public enum IncomingVideoPolicy: CustomStringConvertible, Equatable, Sendable {

    public enum Group: CustomStringConvertible, Equatable, Sendable {

        case all, custom(sessionIds: Set<String>)

        public var description: String {
            switch self {
            case .all:
                return ".all"
            case let .custom(sessionIds):
                return ".custom(\(sessionIds.joined(separator: ",")))"
            }
        }

        func contains(_ sessionId: String) -> Bool {
            switch self {
            case .all:
                return true
            case let .custom(sessionIds: sessionIds):
                return sessionIds.contains(sessionId)
            }
        }
    }

    case none
    case manual(group: Group, targetSize: CGSize)
    case disabled(group: Group)

    public var description: String {
        switch self {
        case .none:
            return ".none"
        case let .manual(group, targetSize):
            return ".manual(group: \(group), targetSize:\(targetSize))"
        case let .disabled(group):
            return ".disabled(group: \(group))"
        }
    }

    var targetSize: CGSize? {
        switch self {
        case .none:
            return nil
        case let .manual(_, targetSize):
            return targetSize
        case .disabled:
            return nil
        }
    }

    func contains(_ sessionId: String) -> Bool {
        switch self {
        case .none:
            return false
        case let .manual(group, _):
            return group.contains(sessionId)
        case let .disabled(group):
            return group.contains(sessionId)
        }
    }

    func isVideoDisabled(for sessionId: String) -> Bool {
        switch self {
        case .none:
            return false
        case .manual:
            return false
        case let .disabled(group):
            return group.contains(sessionId)
        }
    }
}
