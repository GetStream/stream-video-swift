//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

class StreamVideoUITestCase: XCTestCase, @unchecked Sendable {
    
    var streamVideoUI: StreamVideoUI?
    let httpClient: HTTPClient = HTTPClient_Mock()
    let spotlightParticipants = [1, 2, 3, 4]
    let gridParticipants = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    let connectionQuality: [ConnectionQuality] = [.unknown, .poor, .good, .excellent]
    let callId = "test"
    let callType: String = .default
    var callCid: String { "\(callType):\(callId)" }
    let sizeThatFits = CGSize(width: 100, height: 100)
    let snapshotVariants: [SnapshotVariant] = [.defaultLight, .defaultDark]

    override func setUp() async throws {
        try super.setUpWithError()

        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        await streamVideoUI?.streamVideo.disconnect()
    }
}
