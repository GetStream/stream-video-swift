//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo

final class MockInternetConnection: InternetConnectionProtocol, @unchecked Sendable {

    let subject: CurrentValueSubject<InternetConnectionStatus, Never> = .init(.available(.great))
    private let onSubscribe: @Sendable () -> Void

    init(onSubscribe: @escaping @Sendable () -> Void = {}) {
        self.onSubscribe = onSubscribe
    }

    var status: InternetConnectionStatus { subject.value }

    var statusPublisher: AnyPublisher<InternetConnectionStatus, Never> {
        subject
            .handleEvents(receiveSubscription: { [onSubscribe] _ in onSubscribe() })
            .eraseToAnyPublisher()
    }
}
