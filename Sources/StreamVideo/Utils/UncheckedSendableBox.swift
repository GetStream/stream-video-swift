//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value

    init(_ value: Value) {
        self.value = value
    }
}
