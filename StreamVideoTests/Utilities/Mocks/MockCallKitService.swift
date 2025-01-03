//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class MockCallKitService: CallKitService {
    private(set) var reportIncomingCallWasCalled: (cid: String, callerName: String, callerId: String, completion: (Error?) -> Void)?

    override init() { super.init() }

    override func reportIncomingCall(
        _ cid: String,
        localizedCallerName: String,
        callerId: String,
        completion: @escaping ((any Error)?) -> Void
    ) {
        reportIncomingCallWasCalled = (cid, localizedCallerName, callerId, completion)
    }
}
