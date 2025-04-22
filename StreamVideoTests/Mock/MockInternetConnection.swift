//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo

final class MockInternetConnection: InternetConnectionProtocol, @unchecked Sendable {

    let subject: CurrentValueSubject<InternetConnectionStatus, Never> = .init(.available(.great))

    var statusPublisher: AnyPublisher<InternetConnectionStatus, Never> {
        subject.eraseToAnyPublisher()
    }
}
