//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension StoreNamespace {

    static func mockMiddleware() -> MockMiddleware<Self> {
        .init()
    }

    static func mockReducer() -> MockReducer<Self> {
        .init()
    }
}
