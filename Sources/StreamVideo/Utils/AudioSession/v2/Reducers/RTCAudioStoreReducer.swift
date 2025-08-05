//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol RTCAudioStoreReducer {

    func reduce(
        state: RTCAudioStore.State,
        action: RTCAudioStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> RTCAudioStore.State
}
