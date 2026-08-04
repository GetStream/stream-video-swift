//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

final class MockCallKitService: CallKitService, @unchecked Sendable {
    var forwardsReportIncomingCallToSuper = false

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
        completion: @Sendable @escaping ((any Error)?) -> Void
    ) {
        reportIncomingCallWasCalled = (cid, localizedCallerName, callerId, hasVideo, completion)
        guard forwardsReportIncomingCallToSuper else { return }
        super.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: hasVideo ?? false,
            completion: completion
        )
    }

    func send(_ event: Event) {
        eventPipelineSubject.send(event)
    }
}
