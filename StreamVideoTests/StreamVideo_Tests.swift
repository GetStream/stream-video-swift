//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamVideo_Tests: XCTestCase {

    func test_streamVideo_anonymousConnectError() async throws {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: .anonymous,
            token: StreamVideo.mockToken,
            tokenProvider: { _ in }
        )
        
        // Then
        do {
            try await streamVideo.connect()
            XCTFail("connect should fail for anonymous users")
        } catch {
            XCTAssert(error is ClientError.MissingPermissions)
        }
    }
    
    func test_streamVideo_makeCall() {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: StreamVideo.mockUser,
            token: StreamVideo.mockToken,
            tokenProvider: { _ in }
        )
        
        // When
        let call = streamVideo.call(callType: .default, callId: "123")
        
        // Then
        XCTAssert(call.cId == "default:123")
        XCTAssert(call.callType == .default)
        XCTAssert(call.callId == "123")
    }

}
