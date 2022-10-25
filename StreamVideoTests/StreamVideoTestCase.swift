//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

open class StreamVideoTestCase: XCTestCase {

    public var streamVideo: StreamVideo?
    public var httpClient: HTTPClient = MockHTTPClient()

    open override func setUp() {
        super.setUp()
        streamVideo = StreamVideo.mock(httpClient: httpClient)
    }
}
