//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SupportedPrefix_Tests: XCTestCase {

    // MARK: - SupportedPrefix Cases

    func test_supportedPrefixCases() {
        XCTAssertEqual(SupportedPrefix.rtmap.rawValue, "a=rtpmap:")
    }

    // MARK: - SupportedPrefix Set

    func test_supportedPrefixSetContainsRtmap() {
        let supportedPrefixes: Set<SupportedPrefix> = [.rtmap]
        XCTAssertTrue(supportedPrefixes.contains(.rtmap))
    }
}
