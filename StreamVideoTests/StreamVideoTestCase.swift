//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

open class StreamVideoTestCase: XCTestCase {

    public internal(set) lazy var streamVideo: StreamVideo! = StreamVideo.mock(httpClient: httpClient)
    var httpClient: HTTPClient_Mock! = HTTPClient_Mock()
    
    override open func tearDown() async throws {
        try await super.tearDown()
        await streamVideo?.disconnect()
        streamVideo = nil
        httpClient = nil
    }

    override open func tearDown() {
        streamVideo = nil
        httpClient = nil
        super.tearDown()
    }

    // TODO: replace this with something a bit better
    func waitForCallEvent(nanoseconds: UInt64 = 5_000_000_000) async throws {
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}
