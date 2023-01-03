//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

open class StreamVideoUITestCase: XCTestCase {

    public var streamVideoUI: StreamVideoUI?
    public var httpClient: HTTPClient = MockHTTPClient()

    open override func setUp() {
        super.setUp()
        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
    }
}
