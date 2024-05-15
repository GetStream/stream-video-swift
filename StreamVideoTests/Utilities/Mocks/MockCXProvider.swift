//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

final class MockCXProvider: CXProvider {
    var reportNewIncomingCallCalled = false
    var reportNewIncomingCallUpdate: CXCallUpdate?

    convenience init() {
        self.init(configuration: .init(localizedName: "test"))
    }

    override func reportNewIncomingCall(
        with UUID: UUID,
        update: CXCallUpdate,
        completion: @escaping (Error?) -> Void
    ) {
        reportNewIncomingCallCalled = true
        reportNewIncomingCallUpdate = update
        completion(nil)
    }
}
