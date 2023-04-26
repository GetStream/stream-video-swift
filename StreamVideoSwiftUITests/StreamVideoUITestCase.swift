//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import XCTest
import StreamVideo

class StreamVideoUITestCase: XCTestCase {
    
    let spotlightParticipants = [1, 2, 3, 4]
    let gridParticipants = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    let connectionQuality: [ConnectionQuality] = [.unknown, .poor, .good, .excellent]
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
}
