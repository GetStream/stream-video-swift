//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo

final class MockActiveCallProvider: StreamActiveCallProviding, @unchecked Sendable {
    let subject: PassthroughSubject<Bool, Never> = .init()
    var hasActiveCallPublisher: AnyPublisher<Bool, Never> { subject.eraseToAnyPublisher() }

    init() {
        StreamActiveCallProviderKey.currentValue = self
    }
}
