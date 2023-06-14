//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class Mapping_Tests: XCTestCase {

    func test_userResponse_toUser() {
        // Given
        let date = Date()
        let userResponse = UserResponse(
            createdAt: date,
            custom: ["test": "test"],
            id: "test",
            image: "https://test.com",
            name: "test",
            role: "user",
            teams: [],
            updatedAt: date
        )
        
        // When
        let user = userResponse.toUser
        
        // Then
        XCTAssert(user.id == userResponse.id)
        XCTAssert(user.name == userResponse.name)
        XCTAssert(user.role == userResponse.role)
        XCTAssert(user.imageURL?.absoluteString == userResponse.image)
    }
    
    func test_callResponse_toCallData() {
        // Given
        let mockResponseBuilder = MockResponseBuilder()
        let callResponse = mockResponseBuilder.makeCallResponse(cid: "default:test")
        
        // When
        let callData = callResponse.toCallData(members: [], blockedUsers: [])
        
        // Then
        XCTAssert(callData.backstage == false)
        XCTAssert(callData.broadcasting == false)
        XCTAssert(callData.recording == false)
        XCTAssert(callData.autoRejectTimeout == 15000)
        XCTAssert(callData.callCid == "default:test")
        XCTAssert(callData.createdBy.id == "test")
    }

}
