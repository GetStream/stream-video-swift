//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo

final class MockInternetConnection: InternetConnectionProtocol, @unchecked Sendable {

    let subject: CurrentValueSubject<InternetConnection.Status, Never> = .init(.available(.great))

    var statusPublisher: AnyPublisher<InternetConnection.Status, Never> {
        subject.eraseToAnyPublisher()
    }
}
