//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SupportedPrefix_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - SupportedPrefix Cases

    func test_supportedPrefixCases() {
        XCTAssertEqual(SupportedPrefix.rtmap.rawValue, "a=rtpmap:")
        XCTAssertEqual(SupportedPrefix.media.rawValue, "m=")
        XCTAssertEqual(SupportedPrefix.mid.rawValue, "a=mid:")
        XCTAssertEqual(SupportedPrefix.fmtp.rawValue, "a=fmtp:")
    }

    // MARK: - SupportedPrefix Set

    func test_supportedPrefixSetContainsRtmap() {
        let supportedPrefixes: Set<SupportedPrefix> = [.rtmap, .media, .mid, .fmtp]
        XCTAssertTrue(supportedPrefixes.contains(.rtmap))
        XCTAssertTrue(supportedPrefixes.contains(.media))
        XCTAssertTrue(supportedPrefixes.contains(.mid))
        XCTAssertTrue(supportedPrefixes.contains(.fmtp))
    }
}
