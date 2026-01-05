//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An enumeration that defines the types of track information collections
/// available for an RTCPeerConnection.
///
/// - `allAvailable`: Represents a collection type that includes all available
///   track information.
/// - `lastPublishOptions`: Represents a collection type that includes track
///   information based on the last publish options.
enum RTCPeerConnectionTrackInfoCollectionType {
    case allAvailable
    case lastPublishOptions
}
