//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class HLSPlayer_Tests: StreamVideoTestCase, @unchecked Sendable {

    private let url = URL(string: "https://example.com/live.m3u8")!
    private lazy var mockAppState: MockAppStateAdapter! = .init()
    private lazy var audioOutputOn: CurrentValueSubject<Bool, Never>! = .init(true)

    override func tearDown() async throws {
        mockAppState.dismante()
        mockAppState = nil
        audioOutputOn = nil
        try await super.tearDown()
    }

    // MARK: - play

    func test_play_resumeFromLiveEnabled_seeksBehindTheEndByTheRecommendedOffset() {
        let subject = makeSubject(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(90))],
            offset: seconds(6)
        )

        subject.play()

        XCTAssertEqual(subject.seekTimes.last?.seconds, 94)
        XCTAssertEqual(subject.rate, 1)
    }

    func test_play_whileAlreadyPlaying_doesNotSeek() {
        let subject = makeSubject(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(90))],
            offset: seconds(6)
        )
        subject.play()
        let seeks = subject.seekTimes.count

        subject.play()

        XCTAssertEqual(subject.seekTimes.count, seeks)
    }

    func test_play_resumeFromLiveDisabled_doesNotSeek() {
        let subject = makeSubject(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(90))],
            offset: seconds(6)
        )
        subject.resumeFromLive = false

        subject.play()

        XCTAssertTrue(subject.seekTimes.isEmpty)
        XCTAssertEqual(subject.rate, 1)
    }

    func test_play_offsetLargerThanTheRange_clampsToTheStart() {
        let subject = makeSubject(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(20))],
            offset: seconds(100)
        )

        subject.play()

        XCTAssertEqual(subject.seekTimes.last?.seconds, 10)
    }

    func test_play_invalidOffset_seeksToTheEnd() {
        let subject = makeSubject(
            ranges: [CMTimeRange(start: seconds(0), duration: seconds(50))],
            offset: .invalid
        )

        subject.play()

        XCTAssertEqual(subject.seekTimes.last?.seconds, 50)
    }

    func test_play_withoutAUsableRange_doesNotSeekAndPlays() {
        let subject = makeSubject(ranges: [.invalid], offset: seconds(6))

        subject.play()

        XCTAssertTrue(subject.seekTimes.isEmpty)
        XCTAssertEqual(subject.rate, 1)
    }

    func test_play_withoutAnItem_doesNotSeek() {
        let subject = SeekRecordingHLSPlayer()

        subject.play()

        XCTAssertTrue(subject.seekTimes.isEmpty)
    }

    // MARK: - playFromLiveEdge

    func test_playFromLiveEdge_resumeFromLiveDisabled_stillSeeks() {
        let subject = makeSubject(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(90))],
            offset: seconds(6)
        )
        subject.resumeFromLive = false

        subject.playFromLiveEdge()

        XCTAssertEqual(subject.seekTimes.last?.seconds, 94)
        XCTAssertEqual(subject.rate, 1)
    }

    func test_playFromLiveEdge_withoutAUsableRange_doesNotSeekAndPlays() {
        let subject = makeSubject(ranges: [], offset: seconds(6))

        subject.playFromLiveEdge()

        XCTAssertTrue(subject.seekTimes.isEmpty)
        XCTAssertEqual(subject.rate, 1)
    }

    // MARK: - resume after the system pauses the player

    func test_appBecomesActive_playerNotPausedByUser_resumes() async {
        let subject = makeObservedPlayer()

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await fulfillment("The player did not resume.") { subject.playCount == 1 }
    }

    func test_appBecomesActive_playerPlaying_doesNotResume() async {
        let subject = makeObservedPlayer()
        subject.stubbedRate = 1

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await wait(for: 0.3)
        XCTAssertEqual(subject.playCount, 0)
    }

    func test_playerPausedFromOutside_appBecomesActive_staysPaused() async {
        let subject = makeObservedPlayer()

        postRateChange(of: subject, rate: 0, reason: .setRateCalled)
        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await wait(for: 0.3)
        XCTAssertEqual(subject.playCount, 0)
    }

    func test_userPlay_thenTheSystemPausesBeforeTheNotificationIsHandled_staysAUserPlay() async {
        let subject = makeObservedPlayer()

        // The user plays. The system pauses before the main thread handles
        // the notification, so a late read of the rate sees a pause.
        postRateChange(of: subject, rate: 1, reason: .setRateCalled)
        subject.stubbedRate = 0
        await wait(for: 0.1)
        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await fulfillment("The player did not resume.") { subject.playCount == 1 }
    }

    func test_playerResumedFromOutsideAfterPausing_appBecomesActive_resumes() async {
        let subject = makeObservedPlayer()
        // The player reads its rate when it handles the notification on the
        // main thread, so let each one run.
        postRateChange(of: subject, rate: 0, reason: .setRateCalled)
        await wait(for: 0.1)
        postRateChange(of: subject, rate: 1, reason: .setRateCalled)
        await wait(for: 0.1)
        subject.stubbedRate = 0

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await fulfillment("The player did not resume.") { subject.playCount == 1 }
    }

    func test_playerPausedByInterruption_interruptionEnded_resumes() async {
        let subject = makeObservedPlayer()

        postRateChange(of: subject, rate: 0, reason: .audioSessionInterrupted)
        postInterruption(.ended, options: .shouldResume)

        await fulfillment("The player did not resume.") { subject.playCount == 1 }
    }

    func test_interruptionEnded_withoutShouldResume_doesNotResume() async {
        let subject = makeObservedPlayer()

        postInterruption(.ended, options: [])

        await wait(for: 0.3)
        XCTAssertEqual(subject.playCount, 0)
    }

    func test_interruptionBegan_doesNotResume() async {
        let subject = makeObservedPlayer()

        postInterruption(.began, options: .shouldResume)

        await wait(for: 0.3)
        XCTAssertEqual(subject.playCount, 0)
    }

    func test_pause_appBecomesActive_staysPaused() async {
        mockAppState.makeShared()
        let subject = makeSubject(
            ranges: [CMTimeRange(start: seconds(10), duration: seconds(90))],
            offset: seconds(6)
        )
        subject.startObserving(audioOutputOn: audioOutputOn.eraseToAnyPublisher())
        subject.play()
        subject.pause()
        let seeks = subject.seekTimes.count

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await wait(for: 0.3)
        XCTAssertEqual(subject.seekTimes.count, seeks)
        XCTAssertEqual(subject.rate, 0)
    }

    func test_rateChangeFromABackgroundThread_isHandledOnTheMainThread() async {
        let subject = makeObservedPlayer()
        subject.stubbedRate = 0

        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                NotificationCenter.default.post(
                    name: AVPlayer.rateDidChangeNotification,
                    object: subject,
                    userInfo: [
                        AVPlayer.rateDidChangeReasonKey:
                            AVPlayer.RateDidChangeReason.setRateCalled.rawValue
                    ]
                )
                continuation.resume()
            }
        }
        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await wait(for: 0.3)
        XCTAssertEqual(subject.playCount, 0)
    }

    // MARK: - audio output

    func test_audioOutputOff_mutesThePlayerAndOnAgainUnmutesIt() {
        let subject = makeObservedPlayer()

        audioOutputOn.send(false)
        XCTAssertTrue(subject.isMuted)

        audioOutputOn.send(true)
        XCTAssertFalse(subject.isMuted)
    }

    func test_startObserving_audioOutputOff_mutesThePlayerAtOnce() {
        audioOutputOn.send(false)

        let subject = makeObservedPlayer()

        XCTAssertTrue(subject.isMuted)
    }

    // MARK: - invalidate

    func test_invalidate_stopsAndEmptiesThePlayer() {
        let subject = makeObservedPlayer()

        subject.invalidate()

        XCTAssertEqual(subject.pauseCount, 1)
        XCTAssertEqual(subject.replacedItems.count, 1)
        XCTAssertNil(subject.replacedItems.first ?? nil)
    }

    func test_invalidate_thenAppBecomesActive_doesNotResume() async {
        let subject = makeObservedPlayer()
        subject.invalidate()

        mockAppState.stubbedState = .background
        mockAppState.stubbedState = .foreground

        await wait(for: 0.3)
        XCTAssertEqual(subject.playCount, 0)
    }

    func test_invalidate_thenAudioOutputChanges_doesNotMute() {
        let subject = makeObservedPlayer()
        subject.invalidate()

        audioOutputOn.send(false)

        XCTAssertFalse(subject.isMuted)
    }

    // MARK: - load a stream that does not load

    func test_itemFailed_replacesItWithANewItemForTheSameURL() async {
        let (subject, item) = makeLoadingPlayer()

        item.simulate(status: .failed)

        await fulfillment("The item was not loaded again.") { subject.reloadedURLs == [self.url] }
        XCTAssertEqual(subject.playCount, 1)
    }

    func test_itemUnknownAfterTheTimeout_replacesItWithANewItemForTheSameURL() async {
        let (subject, _) = makeLoadingPlayer(loadTimeout: 0.05)

        await fulfillment("The item was not loaded again.") { subject.reloadedURLs.first == self.url }
        // The new item stays unknown too, so it is loaded again until the
        // player gives up. Every attempt uses the same URL.
        subject.invalidate()
        XCTAssertTrue(subject.reloadedURLs.dropLast().allSatisfy { $0 == self.url })
        XCTAssertGreaterThanOrEqual(subject.playCount, 1)
    }

    func test_itemReadyToPlayBeforeTheTimeout_isNotReplaced() async {
        let (subject, item) = makeLoadingPlayer(loadTimeout: 0.2)

        item.simulate(status: .readyToPlay)

        await wait(for: 0.5)
        XCTAssertTrue(subject.reloadedURLs.isEmpty)
    }

    func test_invalidateBeforeTheTimeout_doesNotReplaceTheItem() async {
        let (subject, _) = makeLoadingPlayer(loadTimeout: 0.2)

        subject.invalidate()

        await wait(for: 0.5)
        XCTAssertTrue(subject.reloadedURLs.isEmpty)
    }

    func test_playerPausedByUser_itemUnknownAfterTheTimeout_isReloadedButNotPlayed() async {
        let (subject, _) = makeLoadingPlayer(loadTimeout: 0.2)
        postRateChange(of: subject, rate: 0, reason: .setRateCalled)

        await fulfillment("The item was not loaded again.") { subject.reloadedURLs.first == self.url }
        subject.invalidate()
        XCTAssertEqual(subject.playCount, 0)
    }

    func test_itemReplacedByAnotherURLBeforeTheTimeout_doesNotLoadTheOldURLAgain() async {
        let (subject, _) = makeLoadingPlayer(loadTimeout: 0.2)
        let other = MockHLSPlayerItem(url: URL(string: "https://example.com/other.m3u8")!)
        subject.replaceCurrentItem(with: other)
        other.simulate(status: .readyToPlay)

        await wait(for: 0.5)

        XCTAssertFalse(subject.reloadedURLs.contains(url))
        XCTAssertEqual(subject.reloadedURLs.count, 1)
    }

    func test_itemFailedRepeatedly_givesUpAfterTenReloads() async {
        let (subject, items) = makeFailingPlayer()

        await failLatestItem(of: subject, items: items, times: 12)

        XCTAssertEqual(subject.reloadedURLs.count, 10)
    }

    func test_itemReadyToPlay_resetsTheReloadCount() async {
        let (subject, items) = makeFailingPlayer()
        await failLatestItem(of: subject, items: items, times: 10)
        XCTAssertEqual(subject.reloadedURLs.count, 10)

        items.items.last?.simulate(status: .readyToPlay)
        await failLatestItem(of: subject, items: items, times: 1)

        XCTAssertEqual(subject.reloadedURLs.count, 11)
    }

    // MARK: - Private Helpers

    private func makeObservedPlayer() -> MockHLSPlayer {
        mockAppState.makeShared()
        let player = MockHLSPlayer()
        player.startObserving(audioOutputOn: audioOutputOn.eraseToAnyPublisher())
        return player
    }

    /// A player that loads a stream that never plays. The timings are short.
    private func makeLoadingPlayer(
        loadTimeout: TimeInterval = 60
    ) -> (MockHLSPlayer, MockHLSPlayerItem) {
        mockAppState.makeShared()
        let item = MockHLSPlayerItem(url: url)
        let player = MockHLSPlayer()
        player.stubbedItem = item
        player.loadTimeout = loadTimeout
        player.initialReloadDelay = 0.05
        player.startObserving(audioOutputOn: audioOutputOn.eraseToAnyPublisher())
        return (player, item)
    }

    /// A player whose reloads create items that the test can fail.
    private func makeFailingPlayer() -> (MockHLSPlayer, ItemBox) {
        mockAppState.makeShared()
        let items = ItemBox()
        let first = MockHLSPlayerItem(url: url)
        items.items.append(first)
        let player = MockHLSPlayer()
        player.stubbedItem = first
        player.initialReloadDelay = 0.01
        player.maxReloadDelay = 0.01
        player.makeItem = { [items] url in
            let item = MockHLSPlayerItem(url: url)
            items.items.append(item)
            return item
        }
        player.startObserving(audioOutputOn: audioOutputOn.eraseToAnyPublisher())
        return (player, items)
    }

    /// Fails the latest item and gives the player time to replace it.
    private func failLatestItem(of _: MockHLSPlayer, items: ItemBox, times: Int) async {
        for _ in 0..<times {
            items.items.last?.simulate(status: .failed)
            await wait(for: 0.1)
        }
    }

    private func postRateChange(
        of player: MockHLSPlayer,
        rate: Float,
        reason: AVPlayer.RateDidChangeReason
    ) {
        player.stubbedRate = rate
        NotificationCenter.default.post(
            name: AVPlayer.rateDidChangeNotification,
            object: player,
            userInfo: [AVPlayer.rateDidChangeReasonKey: reason.rawValue]
        )
    }

    private func postInterruption(
        _ type: AVAudioSession.InterruptionType,
        options: AVAudioSession.InterruptionOptions
    ) {
        NotificationCenter.default.post(
            name: AVAudioSession.interruptionNotification,
            object: nil,
            userInfo: [
                AVAudioSessionInterruptionTypeKey: type.rawValue,
                AVAudioSessionInterruptionOptionKey: options.rawValue
            ]
        )
    }

    private func seconds(_ value: Double) -> CMTime {
        CMTime(seconds: value, preferredTimescale: 600)
    }

    private func makeSubject(
        ranges: [CMTimeRange],
        offset: CMTime
    ) -> SeekRecordingHLSPlayer {
        let item = MockHLSPlayerItem(url: url)
        item.ranges = ranges
        item.liveOffset = offset
        return SeekRecordingHLSPlayer(playerItem: item)
    }
}

private final class ItemBox: @unchecked Sendable {
    nonisolated(unsafe) var items: [MockHLSPlayerItem] = []
}
