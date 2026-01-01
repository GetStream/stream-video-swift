//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo

extension StoreNamespace {

    static func makeMockDispatcher() -> MockStoreDispatcher<Self> {
        .init()
    }
}

struct MockStoreDispatcher<Namespace: StoreNamespace>: @unchecked Sendable {

    var recordedActions: [StoreActionBox<Namespace.Action>] { subject.value }
    var publisher: AnyPublisher<[StoreActionBox<Namespace.Action>], Never> { subject.eraseToAnyPublisher() }
    private let subject: CurrentValueSubject<[StoreActionBox<Namespace.Action>], Never> = .init([])

    func handle(
        actions: [StoreActionBox<Namespace.Action>]
    ) {
        let value = subject.value
        subject.send(value + actions)
    }
}
