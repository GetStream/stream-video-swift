//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
@testable import StreamVideo
@preconcurrency import XCTest

final class Credentials_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - decode

    func test_decode_blankCredentialsOfAnHLSGrant_decodesEmptyValues() throws {
        let json = """
        {
            "ice_servers": [],
            "server": { "edge_name": "", "url": "", "ws_endpoint": "" },
            "token": ""
        }
        """

        let subject = try JSONDecoder.streamCore.decode(
            Credentials.self,
            from: Data(json.utf8)
        )

        XCTAssertEqual(subject.token, "")
        XCTAssertEqual(subject.server.url, "")
        XCTAssertEqual(subject.server.wsEndpoint, "")
        XCTAssertEqual(subject.server.edgeName, "")
        XCTAssertTrue(subject.iceServers.isEmpty)
    }
}
