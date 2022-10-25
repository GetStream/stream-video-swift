//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

@MainActor
final class CallViewModel_Tests: StreamVideoTestCase {

    func test_startCall_outgoingState() {
        // Given
        let callViewModel = CallViewModel()
        let participants = [UserInfo(id: "test1"), UserInfo(id: "test2")]
        
        // When
        callViewModel.startCall(callId: "test", participants: participants)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .outgoing)
    }
}
