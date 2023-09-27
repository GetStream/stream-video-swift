//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import OSLog

final class OSLogDestination: BaseLogDestination {

    override func write(message: String) {
        os_log("%{public}s", message)
    }
}
