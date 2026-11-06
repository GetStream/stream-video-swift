//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

@available(iOS 15.0, *)
final class BackgroundEffect_Tests: XCTestCase, @unchecked Sendable {

    func test_allCases_id_isUniqueForEachEffect() {
        let effects = BackgroundEffect.allCases
        let identifiers = effects.map(\.id)

        XCTAssertEqual(
            Set(identifiers).count,
            effects.count,
            "Each background effect needs its own ForEach identity."
        )
    }
}
