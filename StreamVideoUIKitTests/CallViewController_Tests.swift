//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoUIKit
import SnapshotTesting
import XCTest

final class CallViewController_Tests: StreamVideoUITestCase {

    func test_callViewController_outgoingSnapshot() {
        // Given
        let callViewController = CallViewController.make()
        let participants = [User(id: "Test1"), User(id: "Test2")]
        
        // When
        callViewController.startCall(callId: "1234", participants: participants)
        
        // Then
        assertSnapshot(matching: callViewController.view, as: .image)
    }

}
