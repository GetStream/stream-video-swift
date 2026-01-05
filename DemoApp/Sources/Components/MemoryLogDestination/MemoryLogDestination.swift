//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class MemoryLogDestination: BaseLogDestination, @unchecked Sendable {

    override func process(logDetails: LogDetails) {
        LogQueue.insert(logDetails)
    }

    override func write(message: String) {
        /* No-Op */
    }
}
