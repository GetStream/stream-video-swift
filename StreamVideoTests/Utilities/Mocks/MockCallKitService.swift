//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

final class MockCallKitService: CallKitService, @unchecked Sendable {
    private(set) var reportIncomingCallWasCalled: (
        cid: String,
        callerName: String,
        callerId: String,
        hasVideo: Bool?,
        completion: (Error?) -> Void
    )?

    override init() { super.init() }

    override func reportIncomingCall(
        _ cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool?,
        completion: @escaping ((any Error)?) -> Void
    ) {
        reportIncomingCallWasCalled = (cid, localizedCallerName, callerId, hasVideo, completion)
    }

    func send(_ event: Event) {
        eventPipelineSubject.send(event)
    }
}
