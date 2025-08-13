//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

class Reducer<Namespace: StoreNamespace> {
    func reduce(
        state: Namespace.State,
        action: Namespace.Action,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> Namespace.State {
        state
    }
}
