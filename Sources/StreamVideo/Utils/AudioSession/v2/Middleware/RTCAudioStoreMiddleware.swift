//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol RTCAudioStoreMiddleware {

    func apply(
        state: RTCAudioStore.State,
        action: RTCAudioStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}
