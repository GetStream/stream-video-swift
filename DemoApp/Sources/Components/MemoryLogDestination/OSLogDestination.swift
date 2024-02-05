//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import OSLog
import StreamVideo

final class OSLogDestination: BaseLogDestination {

    override func write(message: String) {
        os_log("%{public}s", message)
    }
}
