//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

protocol CallAudioRecordingMiddleware: AnyObject {

    func apply(
        state: CallAudioRecordingStore.State,
        action: CallAudioRecordingAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    )
}
