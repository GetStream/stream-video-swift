//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

final class MockAppStateAdapter: AppStateProviding, @unchecked Sendable {
    var stubbedState: ApplicationState {
        get { subject.value }
        set { subject.send(newValue) }
    }

    lazy var subject: CurrentValueSubject<ApplicationState, Never> = .init(.foreground)
    var state: ApplicationState { subject.value }
    var statePublisher: AnyPublisher<ApplicationState, Never> { subject.eraseToAnyPublisher() }
}
