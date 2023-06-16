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
            token: StreamVideo.mockToken
        )
        
        // Then
        do {
            try await streamVideo.connect()
            XCTFail("connect should fail for anonymous users")
        } catch {
            XCTAssert(error is ClientError.MissingPermissions)
        }
    }
    
    func test_streamVideo_guestUser() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        let response = CreateGuestResponse(
            accessToken: StreamVideo.mockToken.rawValue,
            duration: "",
            user: UserResponse(
                createdAt: Date(),
                custom: [:],
                id: StreamVideo.mockUser.id,
                role: "", teams: [],
                updatedAt: Date()
            )
        )
        let data = try! JSONEncoder.default.encode(response)
        httpClient.dataResponses = [data]
        let streamVideo = try await StreamVideo(
            apiKey: "key1",
            user: .guest("martin"),
            environment: StreamVideo.mockEnvironment(httpClient)
        )
                
        // Then
        let user = streamVideo.user
        // Update the user when the guest response comes.
        XCTAssert(user.id == StreamVideo.mockUser.id)
        // Guest users are assigned ids from the backend.
        XCTAssert(user.id != "martin")
    }
    
    func test_streamVideo_makeCall() {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: StreamVideo.mockUser,
            token: StreamVideo.mockToken
        )
        
        // When
        let call = streamVideo.call(callType: .default, callId: "123")
        
        // Then
        XCTAssert(call.cId == "default:123")
        XCTAssert(call.callType == .default)
        XCTAssert(call.callId == "123")
    }

}
