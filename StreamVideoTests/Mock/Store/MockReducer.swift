//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

final class MockReducer<Namespace: StoreNamespace>: Reducer<Namespace>, @unchecked Sendable {

    struct Input {
        var action: Namespace.Action
        var state: Namespace.State
    }

    private(set) var inputs: [Input] = []

    override func reduce(
        state: Namespace.State,
        action: Namespace.Action,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> Namespace.State {
        inputs.append(.init(action: action, state: state))
        return state
    }
}
