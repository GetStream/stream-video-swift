//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

extension RawJSON {
    #if compiler(>=6.0)
    public nonisolated(unsafe) static let double = number
    #else
    public nonisolated(unsafe) static let double = number
    #endif
}
