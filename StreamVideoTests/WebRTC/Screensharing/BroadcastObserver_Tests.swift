//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class BroadcastObserver_Tests: StreamVideoTestCase, @unchecked Sendable {
    
    let notificationCenter: CFNotificationCenter = CFNotificationCenterGetDarwinNotifyCenter()

    func test_broadcastObserver_states() async throws {
        // Given
        let broadcastObserver = BroadcastObserver()
        broadcastObserver.observe()
        
        // Then
        XCTAssert(broadcastObserver.broadcastState == .notStarted)
        
        // When
        postNotification(BroadcastConstants.broadcastStartedNotification)
        try await waitForCallEvent()
        
        // Then
        XCTAssert(broadcastObserver.broadcastState == .started)
        
        // When
        postNotification(BroadcastConstants.broadcastStoppedNotification)
        try await waitForCallEvent()
        
        // Then
        XCTAssert(broadcastObserver.broadcastState == .finished)
    }
    
    // MARK: - private
    
    private func postNotification(_ name: String) {
        CFNotificationCenterPostNotification(
            notificationCenter,
            CFNotificationName(rawValue: name as CFString),
            nil,
            nil,
            true
        )
    }
}
