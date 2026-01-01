//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class Mapping_Tests: XCTestCase, @unchecked Sendable {

    func test_userResponse_toUser() {
        // Given
        let date = Date()
        let userResponse = UserResponse(
            blockedUserIds: [],
            createdAt: date,
            custom: ["test": "test"],
            id: "test",
            image: "https://test.com",
            language: "en",
            name: "test",
            role: "user",
            teams: [],
            updatedAt: date
        )
        
        // When
        let user = userResponse.toUser
        
        // Then
        XCTAssert(user.id == userResponse.id)
        XCTAssert(user.customData["test"]?.stringValue == userResponse.custom["test"]?.stringValue)
        XCTAssert(user.name == userResponse.name)
        XCTAssert(user.role == userResponse.role)
        XCTAssert(user.imageURL?.absoluteString == userResponse.image)
    }
}
