//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A public enum representing the settings for incoming video streams in a WebRTC
/// session. This enum supports different policies like none, manual, or
/// disabled, each potentially applying to specific session IDs.
public enum IncomingVideoQualitySettings: CustomStringConvertible, Equatable, Sendable {

    /// A nested enum that represents a group of session IDs. The group can
    /// either be all sessions or a custom set of specific session IDs.
    public enum Group: CustomStringConvertible, Equatable, Sendable {

        /// Applies to all sessions.
        case all

        /// A custom set of session IDs.
        case custom(sessionIds: Set<String>)

        /// Provides a string description of the group.
        ///
        /// - Returns: A string representation of the group.
        public var description: String {
            switch self {
            case .all:
                return ".all"
            case let .custom(sessionIds):
                return ".custom(\(sessionIds.joined(separator: ",")))"
            }
        }

        /// Checks if a given session ID is part of the group.
        ///
        /// - Parameter sessionId: The session ID to check.
        /// - Returns: `true` if the session ID is part of the group, otherwise
        ///   `false`.
        func contains(_ sessionId: String) -> Bool {
            switch self {
            case .all:
                return true
            case let .custom(sessionIds):
                return sessionIds.contains(sessionId)
            }
        }
    }

    /// No video streams are enabled for incoming video.
    case none

    /// Allows manual control over which video streams are enabled, based on
    /// the group and a target size for the video.
    ///
    /// - Parameters:
    ///   - group: The group of session IDs to which the policy applies.
    ///   - targetSize: The target resolution size for the video streams.
    case manual(group: Group, targetSize: CGSize)

    /// Disables video streams for the specified group of session IDs.
    ///
    /// - Parameter group: The group of session IDs for which video is disabled.
    case disabled(group: Group)

    /// Provides a string description of the policy.
    ///
    /// - Returns: A string representation of the video policy.
    public var description: String {
        switch self {
        case .none:
            return ".none"
        case let .manual(group, targetSize):
            return ".manual(group: \(group), targetSize: \(targetSize))"
        case let .disabled(group):
            return ".disabled(group: \(group))"
        }
    }

    /// Retrieves the target video size for the policy, if applicable.
    ///
    /// - Returns: The target size if the policy has a manual resolution, or
    ///   `nil` if no target size is applicable.
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

    /// Checks if the policy applies to a specific session ID.
    ///
    /// - Parameter sessionId: The session ID to check.
    /// - Returns: `true` if the policy applies to the session ID; otherwise
    ///   `false`.
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

    /// Determines if video is disabled for a specific session ID.
    ///
    /// - Parameter sessionId: The session ID to check.
    /// - Returns: `true` if video is disabled for the session ID, otherwise
    ///   `false`.
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
