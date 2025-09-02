//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockMiddleware<Namespace: StoreNamespace>: Middleware<Namespace>, @unchecked Sendable {

    private(set) var actionsReceived: [Namespace.Action] = []
    private(set) var actionsDispatched: [Namespace.Action] = []

    var stubbedState: Namespace.State?
    var stubbedDispatcher: Store<Namespace>.Dispatcher?
    var actualDispatcher: Store<Namespace>.Dispatcher?

    override var dispatcher: Store<Namespace>.Dispatcher? {
        get { stubbedDispatcher }
        set { actualDispatcher = newValue }
    }

    override init() {
        super.init()
        stubbedDispatcher = .init { action, delay, file, function, line in
            self.actionsDispatched.append(action)

            self.actualDispatcher?.dispatch(
                action,
                delay: delay,
                file: file,
                function: function,
                line: line
            )
        }
    }

    override func apply(
        state: Namespace.State,
        action: Namespace.Action,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        actionsReceived.append(action)
    }
}
