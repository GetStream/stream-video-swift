//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Date {
    /// The number of milliseconds since 1970-01-01 00:00:00 UTC.
    ///
    /// This converts the date's time interval since the Unix epoch into a
    /// rounded 64-bit integer value in milliseconds. Useful for precise
    /// timestamping or encoding dates for transport in APIs.
    var millisecondsSince1970: Int64 {
        Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}
