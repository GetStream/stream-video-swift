//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension EgressResponse {
    static func dummy(
        broadcasting: Bool = false,
        frameRecording: FrameRecordingResponse? = nil,
        hls: EgressHLSResponse? = nil,
        rtmps: [EgressRTMPResponse] = []
    ) -> EgressResponse {
        .init(
            broadcasting: broadcasting,
            frameRecording: frameRecording,
            hls: hls,
            rtmps: rtmps
        )
    }
}
