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

    private var previousValue: AppStateProviding?
    lazy var subject: CurrentValueSubject<ApplicationState, Never> = .init(.foreground)
    var state: ApplicationState { subject.value }
    var statePublisher: AnyPublisher<ApplicationState, Never> { subject.eraseToAnyPublisher() }

    func dismante() {
        if let previousValue {
            AppStateProviderKey.currentValue = previousValue
            InjectedValues[\.applicationStateAdapter] = previousValue
        }
    }

    /// We call this just before the object that needs to use the mock is about to be created.
    func makeShared() {
        AppStateProviderKey.currentValue = self
        InjectedValues[\.applicationStateAdapter] = self
    }
}
