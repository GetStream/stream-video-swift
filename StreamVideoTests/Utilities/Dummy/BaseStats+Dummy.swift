//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension BaseStats {
    static func dummy(
        bytesSent: Int = 0,
        bytesReceived: Int = 0,
        codec: String = "",
        currentRoundTripTime: Double = 0.0,
        frameWidth: Int = 0,
        frameHeight: Int = 0,
        framesPerSecond: Int = 0,
        jitter: Double = 0.0,
        kind: String = "",
        qualityLimitationReason: String = "",
        rid: String = "",
        ssrc: Int = 0,
        isPublisher: Bool = false
    ) -> BaseStats {
        BaseStats(
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            codec: codec,
            currentRoundTripTime: currentRoundTripTime,
            frameWidth: frameWidth,
            frameHeight: frameHeight,
            framesPerSecond: framesPerSecond,
            jitter: jitter,
            kind: kind,
            qualityLimitationReason: qualityLimitationReason,
            rid: rid,
            ssrc: ssrc,
            isPublisher: isPublisher
        )
    }
}
