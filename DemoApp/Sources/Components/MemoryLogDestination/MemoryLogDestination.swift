//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class MemoryLogDestination: BaseLogDestination {

    override func process(logDetails: LogDetails) {
        LogQueue.insert(logDetails)
    }

    override func write(message: String) {
        /* No-Op */
    }
}
