//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Describes the capabilities that the client supports.
///
/// This type is used by SDK integrators to declare specific functionality
/// their client is capable of handling. These capabilities may affect how
/// the backend or SFU behaves during a call.
public enum ClientCapability: Hashable, Sendable, CaseIterable {

    /// Indicates that the client supports pausing and resuming video for
    /// individual subscribers. When enabled, the backend can pause a
    /// participant’s video for a specific subscriber to save bandwidth.
    case subscriberVideoPause

    /// Initializes a `ClientCapability` from the backend protobuf value.
    ///
    /// - Parameter source: The raw protobuf capability value.
    /// - Returns: A `ClientCapability` or `nil` if the value is unrecognized
    ///   or unspecified.
    init?(_ source: Stream_Video_Sfu_Models_ClientCapability) {
        switch source {
        case .subscriberVideoPause:
            self = .subscriberVideoPause
        case .unspecified:
            return nil
        case .UNRECOGNIZED:
            return nil
        }
    }

    /// Returns the backend-compatible representation of this capability.
    var rawValue: Stream_Video_Sfu_Models_ClientCapability {
        switch self {
        case .subscriberVideoPause:
            return .subscriberVideoPause
        }
    }
}
