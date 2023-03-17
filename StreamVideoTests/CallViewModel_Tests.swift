//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

@MainActor
final class CallViewModel_Tests: StreamVideoTestCase {

    func test_startCall_outgoingState() {
        // Given
        let callViewModel = CallViewModel()
        let participants = [User(id: "test1"), User(id: "test2")]
        
        // When
        callViewModel.startCall(callId: "test", type: "default", participants: participants)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .outgoing)
    }
}
