//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CallKit
import Foundation

#if compiler(>=6.0)
extension CXAction: @retroactive @unchecked Sendable {}
#else
extension CXAction: @unchecked Sendable {}
#endif

final class MockCXCallController: CXCallController, @unchecked Sendable {
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
