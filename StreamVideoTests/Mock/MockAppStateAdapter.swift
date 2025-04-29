//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

final class MockAppStateAdapter: AppStateProviding, @unchecked Sendable {
    var stubbedState: ApplicationState = .foreground

    var state: ApplicationState { stubbedState }
    var statePublisher: AnyPublisher<ApplicationState, Never> { Just(state).eraseToAnyPublisher() }
}
