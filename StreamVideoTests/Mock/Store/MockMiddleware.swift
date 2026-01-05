//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockMiddleware<Namespace: StoreNamespace>: Middleware<Namespace>, @unchecked Sendable {

    private(set) var actionsReceived: [Namespace.Action] = []
    private(set) var actionsDispatched: [StoreActionBox<Namespace.Action>] = []

    var stubbedState: Namespace.State?
    var stubbedDispatcher: Store<Namespace>.Dispatcher?
    var actualDispatcher: Store<Namespace>.Dispatcher?

    override var dispatcher: Store<Namespace>.Dispatcher? {
        get { stubbedDispatcher }
        set { actualDispatcher = newValue }
    }

    override init() {
        super.init()
        stubbedDispatcher = .init { actions, file, function, line in
            self.actionsDispatched.append(contentsOf: actions)
            self.actualDispatcher?.dispatch(
                actions,
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
