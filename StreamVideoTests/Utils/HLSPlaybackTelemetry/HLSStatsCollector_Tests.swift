//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo
import XCTest

final class HLSStatsCollector_Tests: XCTestCase, @unchecked Sendable {

    private lazy var clock: HLSManualClock! = .init()
    private lazy var player: MockHLSPlayer! = .init()
    private var item: MockHLSPlayerItem!
    @Atomic private var firstPlayCount = 0
    private lazy var subject: HLSStatsCollector! = {
        let clock = clock!
        let collector = HLSStatsCollector(
            player: player,
            currentDate: { clock.date }
        )
        collector.onFirstPlay = { [weak self] in self?._firstPlayCount.mutate { $0 += 1 } }
        return collector
    }()

    override func setUp() async throws {
        try await super.setUp()
        // The item initializer runs on the main actor.
        item = await MainActor.run {
            MockHLSPlayerItem(url: URL(string: "https://example.com/live.m3u8")!)
        }
    }

    override func tearDown() async throws {
        _ = await subject.stop()
        subject = nil
        player = nil
        item = nil
        clock = nil
        try await super.tearDown()
    }

    // MARK: - first play

    func test_playing_afterPausedAndPlayingAgain_callsOnFirstPlayOnce() async {
        await subject.startObservingPlayer()

        await simulate(.playing)
        await simulate(.paused)
        await simulate(.playing)

        XCTAssertEqual(firstPlayCount, 1)
    }

    func test_playing_alreadyPlayingWhenObservationStarts_callsOnFirstPlay() async {
        await simulate(.playing)

        await subject.startObservingPlayer()
        await drainQueue()

        XCTAssertEqual(firstPlayCount, 1)
    }

    func test_waiting_beforeTheFirstPlay_doesNotCallOnFirstPlay() async {
        await subject.startObservingPlayer()

        await simulate(.waitingToPlayAtSpecifiedRate, reason: .toMinimizeStalls)

        XCTAssertEqual(firstPlayCount, 0)
    }

    // MARK: - stalls

    func test_waitingBeforeTheFirstPlay_isNotAStall() async throws {
        await subject.startObservingPlayer()

        await simulate(.waitingToPlayAtSpecifiedRate, reason: .toMinimizeStalls)
        clock.advance(by: 2)
        await simulate(.playing)
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallCount, 0)
        XCTAssertEqual(sample.events.map(\.type), ["first_frame"])
    }

    func test_playingThenBufferingThenPlaying_reportsTheStall() async throws {
        await subject.startObservingPlayer()

        await simulate(.playing)
        await simulate(.waitingToPlayAtSpecifiedRate, reason: .toMinimizeStalls)
        clock.advance(by: 1.5)
        await simulate(.playing)
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallCount, 1)
        XCTAssertEqual(sample.stats.stallDurationMs, 1500)
        XCTAssertEqual(sample.stats.maxStallDurationMs, 1500)
        XCTAssertEqual(
            sample.events.map(\.type),
            ["first_frame", "stall_start", "stall_end"]
        )
        XCTAssertEqual(sample.events.last?.data, ["duration_ms": .number(1500)])
    }

    func test_playingThenEvaluatingTheBufferingRate_isAStall() async throws {
        await subject.startObservingPlayer()

        await simulate(.playing)
        await simulate(.waitingToPlayAtSpecifiedRate, reason: .evaluatingBufferingRate)
        await simulate(.playing)
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallCount, 1)
    }

    func test_playingThenNoItemToPlay_isNotAStall() async throws {
        await subject.startObservingPlayer()

        await simulate(.playing)
        await simulate(.waitingToPlayAtSpecifiedRate, reason: .noItemToPlay)
        await simulate(.playing)
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallCount, 0)
    }

    func test_playingThenWaitingWithoutAReason_isAStall() async throws {
        await subject.startObservingPlayer()

        await simulate(.playing)
        await simulate(.waitingToPlayAtSpecifiedRate)
        await simulate(.playing)
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallCount, 1)
    }

    func test_userPauseThenResumeBuffering_isNotAStall() async throws {
        await subject.startObservingPlayer()

        await simulate(.playing)
        await simulate(.paused)
        await simulate(.waitingToPlayAtSpecifiedRate, reason: .toMinimizeStalls)
        await simulate(.playing)
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallCount, 0)
    }

    /// The queue can run late when the main thread is busy.
    func test_stall_whenTheQueueRunsLate_usesTheTimeOfEachChange() async throws {
        await subject.startObservingPlayer()
        await simulate(.playing)
        let stallBeganAt = clock.date
        subject.playbackQueue.isSuspended = true

        player.simulate(.waitingToPlayAtSpecifiedRate, reason: .toMinimizeStalls)
        clock.advance(by: 2)
        player.simulate(.playing)
        clock.advance(by: 3)
        subject.playbackQueue.isSuspended = false
        await drainQueue()
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallDurationMs, 2000)
        XCTAssertEqual(
            sample.events.first { $0.type == "stall_start" }?.timestamp,
            Int(stallBeganAt.timeIntervalSince1970 * 1000)
        )
    }

    func test_pauseDuringAStall_closesTheStall() async throws {
        await subject.startObservingPlayer()
        await simulate(.playing)
        await simulate(.waitingToPlayAtSpecifiedRate, reason: .toMinimizeStalls)
        clock.advance(by: 1)

        await simulate(.paused)
        let sample = try await snapshot()

        XCTAssertEqual(sample.stats.stallDurationMs, 1000)
        XCTAssertEqual(sample.events.last?.type, "stall_end")
    }

    // MARK: - playback errors

    func test_itemFails_reportsTheErrorOnStop() async throws {
        player.stubbedItem = item
        await subject.startObservingPlayer()

        item.fail(with: NSError(domain: "AVFoundationErrorDomain", code: -11800))
        let result = try await stopped()

        XCTAssertEqual(result.errorCode, "AVFoundationErrorDomain -11800")
        XCTAssertEqual(result.events.map(\.type), ["error"])
        XCTAssertEqual(result.events.first?.data, ["code": .string("AVFoundationErrorDomain -11800")])
    }

    func test_itemFailsToPlayToEnd_reportsTheErrorOnStop() async throws {
        player.stubbedItem = item
        await subject.startObservingPlayer()

        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            userInfo: [
                AVPlayerItemFailedToPlayToEndTimeErrorKey: NSError(
                    domain: "CoreMediaErrorDomain",
                    code: -12642
                )
            ]
        )
        let result = try await stopped()

        XCTAssertEqual(result.errorCode, "CoreMediaErrorDomain -12642")
    }

    func test_failedToPlayToEnd_ofAnotherItem_isIgnored() async throws {
        player.stubbedItem = item
        await subject.startObservingPlayer()

        NotificationCenter.default.post(
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: AVPlayerItem(url: URL(string: "https://example.com/other.m3u8")!),
            userInfo: [
                AVPlayerItemFailedToPlayToEndTimeErrorKey: NSError(domain: "Other", code: 1)
            ]
        )
        let result = try await stopped()

        XCTAssertNil(result.errorCode)
    }

    func test_itemBecomesReady_afterAnError_clearsTheError() async throws {
        player.stubbedItem = item
        await subject.startObservingPlayer()
        item.fail(with: NSError(domain: "AVFoundationErrorDomain", code: -11800))

        item.simulate(status: .readyToPlay)
        let result = try await stopped()

        XCTAssertNil(result.errorCode)
        XCTAssertEqual(result.events.map(\.type), ["error"])
    }

    func test_playerPlays_afterAnError_clearsTheError() async throws {
        player.stubbedItem = item
        await subject.startObservingPlayer()
        item.fail(with: NSError(domain: "AVFoundationErrorDomain", code: -11800))

        player.simulate(.playing)
        let result = try await stopped()

        XCTAssertNil(result.errorCode)
    }

    func test_sameErrorAgain_afterRecovering_isRecordedAgain() async throws {
        player.stubbedItem = item
        await subject.startObservingPlayer()
        let error = NSError(domain: "AVFoundationErrorDomain", code: -11800)
        item.fail(with: error)
        item.simulate(status: .readyToPlay)

        item.fail(with: error)
        let result = try await stopped()

        XCTAssertEqual(result.errorCode, "AVFoundationErrorDomain -11800")
        XCTAssertEqual(result.events.map(\.type), ["error", "error"])
    }

    func test_sameErrorTwice_isRecordedOnce() async throws {
        player.stubbedItem = item
        await subject.startObservingPlayer()
        let error = NSError(domain: "AVFoundationErrorDomain", code: -11800)

        item.fail(with: error)
        item.fail(with: error)
        let result = try await stopped()

        XCTAssertEqual(result.events.map(\.type), ["error"])
    }

    // MARK: - quality

    func test_secondSnapshotWithAnotherQuality_reportsTheValuesAsNumbers() async throws {
        player.stubbedItem = item
        item.size = CGSize(width: 1280, height: 720)
        await subject.startObservingPlayer()
        _ = try await snapshot()

        item.size = CGSize(width: 1920, height: 1080)
        let sample = try await snapshot()

        XCTAssertEqual(sample.events.map(\.type), ["quality_change"])
        XCTAssertEqual(
            sample.events.first?.data,
            [
                "bitrate_kbps": .number(0),
                "width": .number(1920),
                "height": .number(1080)
            ]
        )
    }

    func test_secondSnapshotWithOnlyAnotherBitrate_reportsTheQualityChange() async throws {
        player.stubbedItem = item
        item.size = CGSize(width: 1280, height: 720)
        item.bitrate = 900_000
        await subject.startObservingPlayer()
        _ = try await snapshot()

        item.bitrate = 2_000_000
        let sample = try await snapshot()

        XCTAssertEqual(sample.events.map(\.type), ["quality_change"])
        XCTAssertEqual(
            sample.events.first?.data,
            [
                "bitrate_kbps": .number(2000),
                "width": .number(1280),
                "height": .number(720)
            ]
        )
    }

    func test_secondSnapshotWithTheSameQuality_reportsNoEvent() async throws {
        player.stubbedItem = item
        item.size = CGSize(width: 1280, height: 720)
        item.bitrate = 900_000
        await subject.startObservingPlayer()
        _ = try await snapshot()

        let sample = try await snapshot()

        XCTAssertTrue(sample.events.isEmpty)
    }

    func test_stop_afterASnapshot_findsTheEventsAlreadyDelivered() async {
        await subject.startObservingPlayer()
        await simulate(.playing)
        let delivered = Sample()
        subject.playbackQueue.isSuspended = true

        let snapshotting = Task {
            await subject.snapshot { stats, events in
                // A slow hand-off must finish before the stop starts.
                Thread.sleep(forTimeInterval: 0.2)
                delivered.value = (stats, events)
            }
        }
        await fulfillment { self.subject.playbackQueue.operationCount == 1 }
        let stopping = Task { await subject.stop() }
        await fulfillment { self.subject.playbackQueue.operationCount == 2 }
        subject.playbackQueue.isSuspended = false
        let sample = await stopping.value
        await snapshotting.value

        XCTAssertEqual(delivered.value?.events.map(\.type), ["first_frame"])
        XCTAssertEqual(sample?.events.map(\.type), [])
    }

    // MARK: - Private Helpers

    /// Waits until the collector applied the changes queued so far, so the
    /// clock reads the time of this step.
    private func drainQueue() async {
        try? await subject.playbackQueue.addSynchronousTaskOperation {}
    }

    private func simulate(
        _ status: AVPlayer.TimeControlStatus,
        reason: AVPlayer.WaitingReason? = nil
    ) async {
        player.simulate(status, reason: reason)
        await drainQueue()
    }

    private func snapshot() async throws -> (stats: HLSPlaybackStats, events: [HLSPlayerEvent]) {
        let sample = Sample()
        await subject.snapshot { stats, events in sample.value = (stats, events) }
        return try XCTUnwrap(sample.value)
    }

    private func stopped() async throws -> (
        stats: HLSPlaybackStats,
        events: [HLSPlayerEvent],
        errorCode: String?
    ) {
        let result = await subject.stop()
        return try XCTUnwrap(result)
    }

    /// Keeps what a sendable `deliver` closure received.
    private final class Sample: @unchecked Sendable {
        var value: (stats: HLSPlaybackStats, events: [HLSPlayerEvent])?
    }
}
