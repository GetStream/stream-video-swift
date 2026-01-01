//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

extension StreamRTCStatisticsReport {

    static func dummy(
        statistics: [StreamRTCStatistics] = [],
        timestamp: TimeInterval = 0
    ) -> StreamRTCStatisticsReport {
        .init(
            statistics: statistics,
            timestamp: timestamp,
            source: nil
        )
    }
}

extension StreamRTCStatistics {

    static func dummy(
        type: String = "",
        id: String = "",
        timestamp: TimeInterval = 0,
        values: [String: NSObject] = [:]
    ) -> StreamRTCStatistics {
        .init(
            MockStreamStatistics(
                timestamp_us: timestamp,
                type: type,
                id: id,
                values: values
            )
        )!
    }
}
