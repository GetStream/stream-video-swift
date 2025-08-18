//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension StoreNamespace {

    static func spyMiddleware() -> SpyMiddleware<Self> {
        .init()
    }
}

final class SpyMiddleware<Namespace: StoreNamespace>: Middleware<Namespace> {

    private(set) var actionsReceived: [Namespace.Action] = []
    private(set) var actionsDispatched: [Namespace.Action] = []

    var stubbedState: Namespace.State?
    var stubbedDispatcher: ((Namespace.Action) -> Void)?
    var actualDispatcher: ((Namespace.Action) -> Void)?

    override var dispatcher: ((Namespace.Action) -> Void)? {
        get { stubbedDispatcher }
        set { actualDispatcher = newValue }
    }

    static func make() -> SpyMiddleware<Namespace> { Namespace.spyMiddleware() }

    override init() {
        super.init()
        stubbedDispatcher = {
            self.actionsDispatched.append($0)
            self.actualDispatcher?($0)
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
