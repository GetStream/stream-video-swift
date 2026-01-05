//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Represents the type of peer connection in a WebRTC communication.
enum PeerConnectionType: String, Codable {
    /// Indicates a peer connection that is receiving media.
    case subscriber
    /// Indicates a peer connection that is sending media.
    case publisher
}
