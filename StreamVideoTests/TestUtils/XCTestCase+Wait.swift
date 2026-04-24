//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

extension XCTestCase {

    func wait(for interval: TimeInterval) async {
        guard interval > 0 else { return }
        let nanoseconds = UInt64((interval * 1_000_000_000).rounded())
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}
