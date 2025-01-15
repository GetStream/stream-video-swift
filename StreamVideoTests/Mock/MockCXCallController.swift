//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

final class MockCXCallController: CXCallController {
    private(set) var requestWasCalledWith: (CXTransaction, (Error?) -> Void)?

    func reset() { requestWasCalledWith = nil }

    override func request(
        _ transaction: CXTransaction,
        completion: @escaping ((any Error)?) -> Void
    ) {
        requestWasCalledWith = (transaction, completion)
    }

    override func requestTransaction(with action: CXAction) async throws {
        requestWasCalledWith = (.init(action: action), { _ in })
    }
}
