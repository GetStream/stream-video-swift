//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The URLs and players a store built, in order.
final class MadePlayers: @unchecked Sendable {
    var urls: [URL] = []
    var players: [MockHLSPlayer] = []
}
