//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

open class StreamVideoTestCase: XCTestCase {

    public var streamVideo: StreamVideo?
    public var httpClient: HTTPClient = HTTPClient_Mock()

    open override func setUp() {
        super.setUp()
        streamVideo = StreamVideo.mock(httpClient: httpClient)
        Task {
            try await streamVideo?.connect()
        }
    }
}
