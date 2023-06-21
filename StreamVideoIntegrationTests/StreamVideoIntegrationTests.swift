//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

open class StreamVideoTestCase: XCTestCase {

    open override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    open override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    func testExample() {
        let token = fetchToken(for: "user1", expiration: 1)
        XCTAssertNotNil(token)
    }
    
    func fetchToken(for userId: String, expiration: Double = 0) -> UserToken? {
        return TokenGenerator.shared.generateUserToken(userId: userId, tokenDurationInMinutes: expiration)
    }
}
