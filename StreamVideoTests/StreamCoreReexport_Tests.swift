//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import XCTest

final class StreamCoreReexport_Tests: XCTestCase, @unchecked Sendable {
    func test_streamVideo_reexportsStreamCore() {
        _ = DefaultEventNotificationCenter()
    }
}
