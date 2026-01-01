//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallStatisticsFormatter_Tests: XCTestCase, @unchecked Sendable {

    private var subject: StreamCallStatisticsFormatter!

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: Test cases

    // MARK: - base

    func test_base_directionOutbound_trackAudio_returnsExpectedResult() {
        assertBaseReport(direction: .outbound, trackKind: .audio)
    }

    func test_base_directionOutbound_trackVideo_returnsExpectedResult() {
        assertBaseReport(direction: .outbound, trackKind: .video)
    }

    func test_base_directionInbound_trackAudio_returnsExpectedResult() {
        assertBaseReport(direction: .inbound, trackKind: .audio)
    }

    func test_base_directionInbound_trackVideo_returnsExpectedResult() {
        assertBaseReport(direction: .inbound, trackKind: .video)
    }

    func test_base_transportExists_dtlsStateNotConnected_returnsExpectedResult() {
        assertRoundTripTime(
            containsTransportStatistic: true,
            transportStatisticDTLSState: "disconnected",
            containsCandidatePairStatistic: false,
            expectedRoundTripTime: 0
        )
    }

    func test_base_transportExists_dtlsStateConnected_candidatePairDoesNotExist_returnsExpectedResult() {
        assertRoundTripTime(
            containsTransportStatistic: true,
            transportStatisticDTLSState: "connected",
            containsCandidatePairStatistic: false,
            expectedRoundTripTime: 0
        )
    }

    func test_base_transportExists_dtlsStateConnected_candidatePairExists_returnsExpectedResult() {
        assertRoundTripTime(
            containsTransportStatistic: true,
            transportStatisticDTLSState: "connected",
            containsCandidatePairStatistic: true,
            expectedRoundTripTime: 100
        )
    }

    func test_base_transportDoesNotExist_dtlsStateConnected_returnsExpectedResult() {
        assertRoundTripTime(
            containsTransportStatistic: false,
            transportStatisticDTLSState: "connected",
            containsCandidatePairStatistic: true,
            expectedRoundTripTime: 0
        )
    }

    func test_base_codecExists_returnsExpectedResult() {
        assertCodec(containsCodec: true, expectedMimeType: "video/h264")
    }

    func test_base_codecDoesNotExist_returnsExpectedResult() {
        assertCodec(containsCodec: false, expectedMimeType: "")
    }

    // MARK: - aggregated

    func test_aggregated_1BaseStat_returnsExpectedResult() {
        assertAggregated(count: 1)
    }

    func test_aggregated_2BaseStat_returnsExpectedResult() {
        assertAggregated(count: 2)
    }

    func test_aggregated_3BaseStat_returnsExpectedResult() {
        assertAggregated(count: 3)
    }

    // MARK: - participantsReport

    func test_participantsReport_publisher_returnsExpectedResult() {
        assertParticipantsReport(direction: .outbound)
    }

    func test_participantsReport_subscriber_returnsExpectedResult() {
        assertParticipantsReport(direction: .inbound)
    }

    // MARK: - Assertions

    private func assertBaseReport(
        direction: StreamCallStatisticsFormatter.Direction,
        trackKind: StreamCallStatisticsFormatter.TrackKind,
        additionalStatistics: @autoclosure () -> [MockStreamStatistics] = [],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let rawData = [
            (direction: StreamCallStatisticsFormatter.Direction.outbound, kind: StreamCallStatisticsFormatter.TrackKind.audio),
            (direction: StreamCallStatisticsFormatter.Direction.inbound, kind: StreamCallStatisticsFormatter.TrackKind.audio),
            (direction: StreamCallStatisticsFormatter.Direction.outbound, kind: StreamCallStatisticsFormatter.TrackKind.video),
            (direction: StreamCallStatisticsFormatter.Direction.inbound, kind: StreamCallStatisticsFormatter.TrackKind.video)
        ]
        let expectedIndex = rawData.firstIndex { $0.direction == direction && $0.kind == trackKind } ?? -1

        let statistics: [MockStreamStatistics] = rawData
            .enumerated()
            .map { rawData in
                makeMock(
                    type: rawData.element.direction.rawValue,
                    kind: rawData.element.kind.rawValue,
                    id: "\(rawData.offset)"
                ) { mock in mock.rid = "\(rawData.offset)" }
            }

        prepare(
            trackKind: trackKind,
            direction: direction,
            (statistics + additionalStatistics())
        )

        XCTAssertEqual(subject.baseReport.count, 1, file: file, line: line)
        XCTAssertEqual(subject.baseReport.first?.kind, trackKind.rawValue, file: file, line: line)
        XCTAssertEqual(subject.baseReport.first?.rid, "\(expectedIndex)", file: file, line: line)
    }

    private func assertRoundTripTime(
        containsTransportStatistic: Bool,
        transportStatisticDTLSState: String,
        containsCandidatePairStatistic: Bool,
        expectedRoundTripTime: Double,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let transportId = String.unique
        let candidatePairId = String.unique

        var statistics: [MockStreamStatistics] = [
            /// Just some random data to ensure that selecting works correctly.
            makeMock(
                trackKind: .audio,
                direction: .outbound,
                update: { $0.transportId = transportId }
            ),
            
            ///  The statistics instance we actually care about.
            makeMock(
                trackKind: .video,
                direction: .outbound,
                update: { $0.transportId = transportId }
            )
        ]

        if containsTransportStatistic {
            statistics.append(
                ///  The statistics instance that contains the information about transport info.
                makeMock(
                    type: StreamCallStatisticsFormatter.RTCStatisticType.transport.rawValue,
                    kind: .unique,
                    id: transportId,
                    update: {
                        $0.selectedCandidatePairId = candidatePairId
                        $0.dtlsState = transportStatisticDTLSState
                    }
                )
            )
        }

        if containsCandidatePairStatistic {
            statistics.append(
                ///  The statistics instance that contains the information about ICE candidatePair  info.
                makeMock(
                    type: StreamCallStatisticsFormatter.RTCStatisticType.candidatePair.rawValue,
                    kind: .unique,
                    id: candidatePairId,
                    update: { $0.currentRoundTripTime = expectedRoundTripTime }
                )
            )
        }

        prepare(
            trackKind: .video,
            direction: .outbound,
            statistics
        )

        XCTAssertEqual(
            subject.baseReport.first?.currentRoundTripTime,
            expectedRoundTripTime,
            file: file,
            line: line
        )
    }

    private func assertCodec(
        containsCodec: Bool,
        expectedMimeType: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let codecId = String.unique

        var statistics: [MockStreamStatistics] = [
            /// Just some random data to ensure that selecting works correctly.
            makeMock(
                trackKind: .audio,
                direction: .outbound,
                update: { $0.codecId = codecId }
            ),
            
            ///  The statistics instance we actually care about.
            makeMock(
                trackKind: .video,
                direction: .outbound,
                update: { $0.codecId = codecId }
            )
        ]

        if containsCodec {
            statistics.append(
                ///  The statistics instance that contains the information about the codec in use.
                makeMock(
                    type: StreamCallStatisticsFormatter.RTCStatisticType.codec.rawValue,
                    kind: .unique,
                    id: codecId,
                    update: {
                        $0.mimeType = expectedMimeType
                    }
                )
            )
        }

        prepare(
            trackKind: .video,
            direction: .outbound,
            statistics
        )

        if containsCodec {
            XCTAssertFalse(expectedMimeType.isEmpty, file: file, line: line)
        } else {
            XCTAssertTrue(expectedMimeType.isEmpty, file: file, line: line)
        }
        XCTAssertEqual(
            subject.baseReport.first?.codec,
            expectedMimeType,
            file: file,
            line: line
        )
    }

    private func assertAggregated(
        count: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let rawData: [Int] = (1...count).map { $0 }
        let statistics: [MockStreamStatistics] = rawData.reduce(into: [MockStreamStatistics]()) { partialResult, index in
            let transportId = String.unique
            let candidatePairId = String.unique

            partialResult.append(
                makeMock(
                    trackKind: .video,
                    direction: .outbound,
                    update: { mock in
                        mock.bytesSent = index
                        mock.bytesReceived = index
                        mock.jitter = Double(index)
                        mock.currentRoundTripTime = Double(index)
                        mock.qualityLimitationReason = "\(index)"
                        mock.frameWidth = index
                        mock.frameHeight = index
                        mock.framesPerSecond = 60 / index
                        mock.transportId = transportId
                    }
                )
            )

            // Append the required statistics in order to calculate correctly
            // the currentRoundTripTime

            partialResult.append(
                makeMock(
                    type: StreamCallStatisticsFormatter.RTCStatisticType.transport.rawValue,
                    kind: .unique,
                    id: transportId,
                    update: {
                        $0.selectedCandidatePairId = candidatePairId
                        $0.dtlsState = "connected"
                    }
                )
            )

            partialResult.append(
                ///  The statistics instance that contains the information about ICE candidatePair  info.
                makeMock(
                    type: StreamCallStatisticsFormatter.RTCStatisticType.candidatePair.rawValue,
                    kind: .unique,
                    id: candidatePairId,
                    update: { $0.currentRoundTripTime = Double(index) }
                )
            )
        }

        prepare(
            trackKind: .video,
            direction: .outbound,
            timestamp: 10,
            statistics
        )

        let sumRawData = rawData.reduce(0, +)
        let expected = AggregatedStatsReport(
            totalBytesSent: sumRawData,
            totalBytesReceived: sumRawData,
            averageJitterInMs: (Double(sumRawData) / Double(count)) * 1000,
            averageRoundTripTimeInMs: (Double(sumRawData) / Double(count)) * 1000,
            qualityLimitationReasons: rawData.map { "\($0)" }.joined(separator: ","),
            highestFrameWidth: count,
            highestFrameHeight: count,
            highestFramesPerSecond: 60 / count,
            timestamp: 10
        )

        XCTAssertEqual(subject.aggregatedReport, expected, file: file, line: line)
    }

    private func assertParticipantsReport(
        direction: StreamCallStatisticsFormatter.Direction,
        count: Int = 3,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let transportIds = (0..<count).map { _ in String.unique }
        var statistics: [MockStreamStatistics] = []

        for (index, transportId) in transportIds.enumerated() {
            let candidatePairId = String.unique

            switch direction {
            case .inbound:
                let trackIdentifier = String.unique
                statistics.append(
                    makeMock(
                        trackKind: .video,
                        direction: direction,
                        update: { mock in
                            mock.trackIdentifier = trackIdentifier
                            mock.bytesSent = index
                            mock.bytesReceived = index
                            mock.jitter = Double(index)
                            mock.currentRoundTripTime = Double(index)
                            mock.qualityLimitationReason = "\(index)"
                            mock.frameWidth = index
                            mock.frameHeight = index
                            mock.framesPerSecond = index
                            mock.transportId = transportId
                        }
                    )
                )
            case .outbound:
                let trackIdentifier = "publisher-statistic"

                statistics.append(
                    makeMock(
                        trackKind: .video,
                        direction: direction,
                        update: { mock in
                            mock.bytesSent = index
                            mock.bytesReceived = index
                            mock.jitter = Double(index)
                            mock.currentRoundTripTime = Double(index)
                            mock.qualityLimitationReason = "\(index)"
                            mock.frameWidth = index
                            mock.frameHeight = index
                            mock.framesPerSecond = index
                            mock.transportId = transportId
                        }
                    )
                )

                statistics.append(
                    makeMock(
                        type: "any-publisher-statistic",
                        kind: "any-publisher-statistic",
                        id: .unique,
                        update: { $0.trackIdentifier = trackIdentifier }
                    )
                )
            }

            // Append the required statistics in order to calculate correctly
            // the currentRoundTripTime

            statistics.append(
                makeMock(
                    type: StreamCallStatisticsFormatter.RTCStatisticType.transport.rawValue,
                    kind: .unique,
                    id: transportId,
                    update: {
                        $0.selectedCandidatePairId = candidatePairId
                        $0.dtlsState = "connected"
                    }
                )
            )

            statistics.append(
                ///  The statistics instance that contains the information about ICE candidatePair  info.
                makeMock(
                    type: StreamCallStatisticsFormatter.RTCStatisticType.candidatePair.rawValue,
                    kind: .unique,
                    id: candidatePairId,
                    update: { $0.currentRoundTripTime = Double(index) }
                )
            )
        }

        prepare(
            trackKind: .video,
            direction: direction,
            statistics
        )

        switch direction {
        case .inbound:
            XCTAssertEqual(
                subject.participantsReport.report.keys.count,
                3,
                file: file,
                line: line
            )

            let values = subject.participantsReport.report.values.map { $0 }
            XCTAssertEqual(
                values[0].count,
                1,
                file: file,
                line: line
            )
            XCTAssertEqual(
                values[1].count,
                1,
                file: file,
                line: line
            )
            XCTAssertEqual(
                values[2].count,
                1,
                file: file,
                line: line
            )
        case .outbound:
            XCTAssertEqual(
                subject.participantsReport.report.keys.count,
                1,
                file: file,
                line: line
            )

            XCTAssertEqual(
                subject.participantsReport.report.first?.value.count,
                3,
                file: file,
                line: line
            )
        }
    }

    // MARK: - Private Helpers

    private func prepare(
        trackKind: StreamCallStatisticsFormatter.TrackKind,
        direction: StreamCallStatisticsFormatter.Direction,
        timestamp: TimeInterval = 0,
        _ statistics: @autoclosure () -> [MockStreamStatistics]
    ) {
        subject = .init(
            statistics: statistics().compactMap(StreamRTCStatistics.init),
            timestamp: timestamp,
            trackKind: trackKind,
            direction: direction
        )
    }

    private func makeMock(
        trackKind: StreamCallStatisticsFormatter.TrackKind,
        direction: StreamCallStatisticsFormatter.Direction,
        id: String = .unique,
        update: (inout MockStreamStatistics) -> Void = { _ in }
    ) -> MockStreamStatistics {
        makeMock(
            type: direction.rawValue,
            kind: trackKind.rawValue,
            id: id,
            update: update
        )
    }

    private func makeMock(
        type: String,
        kind: String,
        id: String,
        update: (inout MockStreamStatistics) -> Void = { _ in }
    ) -> MockStreamStatistics {
        var result = MockStreamStatistics(
            timestamp_us: 123_456,
            type: type,
            id: id
        )
        result.kind = kind
        update(&result)
        return result
    }
}
