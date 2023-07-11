//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

open class StreamVideoTestCase: XCTestCase {

    public var streamVideo: StreamVideo?
    var httpClient = HTTPClient_Mock()

    open override func setUp() {
        super.setUp()
        streamVideo = StreamVideo.mock(httpClient: httpClient)
    }
    
    // TODO: replace this with something a bit better
    func waitForCallEvent(nanoseconds: UInt64 = 500_000_000) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
