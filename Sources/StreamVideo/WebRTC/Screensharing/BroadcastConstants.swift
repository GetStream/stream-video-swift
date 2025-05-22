//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

enum BroadcastConstants {
    static let bufferMaxLength = 10240
    static let contentLength = "Content-Length"
    static let bufferWidth = "Buffer-Width"
    static let bufferHeight = "Buffer-Height"
    static let bufferOrientation = "Buffer-Orientation"
    static let broadcastStartedNotification = "io.getstream.broadcastStarted"
    static let broadcastStoppedNotification = "io.getstream.broadcastStopped"
    static let broadcastSharePath = "broadcast_share"
    static let broadcastAppGroupIdentifier = "BroadcastAppGroupIdentifier"
}
