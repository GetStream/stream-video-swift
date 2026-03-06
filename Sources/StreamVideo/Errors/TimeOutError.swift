//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Indicates that an asynchronous operation exceeded its configured timeout.
public final class TimeOutError: ClientError, Sendable {

    convenience init(
        file: StaticString = #fileID,
        line: UInt = #line
    ) {
        self.init("Operation timed out", file, line)
    }
}
