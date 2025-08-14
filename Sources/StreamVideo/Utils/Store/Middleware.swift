//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

class Middleware<Namespace: StoreNamespace> {
    var dispatcher: ((Namespace.Action) -> Void)?
    var stateProvider: (() -> Namespace.State?)?

    var state: Namespace.State? { stateProvider?() }

    func apply(
        state: Namespace.State,
        action: Namespace.Action,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {}
}
