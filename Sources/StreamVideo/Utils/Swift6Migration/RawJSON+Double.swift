//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension RawJSON {
    #if swift(>=6.0)
    public static let double = number
    #else
    public nonisolated(unsafe) static let double = number
    #endif
}
