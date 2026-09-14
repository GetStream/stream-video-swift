//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension DeleteCallResponse {
    static func dummy(
        call: CallResponse = .dummy(),
        duration: String = "0",
        taskId: String? = nil
    ) -> DeleteCallResponse {
        .init(
            call: call,
            duration: duration,
            taskId: taskId
        )
    }
}
