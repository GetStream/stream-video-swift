//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// A clock that moves only when a test advances it.
final class HLSManualClock: @unchecked Sendable {
    @Atomic var date = Date(timeIntervalSince1970: 1_700_000_000)

    func advance(by seconds: TimeInterval) {
        date = date.addingTimeInterval(seconds)
    }
}
