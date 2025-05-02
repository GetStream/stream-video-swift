//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}
