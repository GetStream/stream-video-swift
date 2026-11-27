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
        let subject = SeekRecordingPlayer()

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

    func test_playerResumedFromOutsideAfterPausing_appBecomesActive_resumes() async {
        let subject = makeObservedPlayer()
        postRateChange(of: subject, rate: 0, reason: .setRateCalled)
        postRateChange(of: subject, rate: 1, reason: .setRateCalled)
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

    // MARK: - Private Helpers

    private func makeObservedPlayer() -> MockHLSPlayer {
        mockAppState.makeShared()
        let player = MockHLSPlayer()
        player.startObserving(audioOutputOn: audioOutputOn.eraseToAnyPublisher())
        return player
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
    ) -> SeekRecordingPlayer {
        let item = MockHLSPlayerItem(url: url)
        item.ranges = ranges
        item.liveOffset = offset
        return SeekRecordingPlayer(playerItem: item)
    }
}

/// Records the seeks, and keeps the real `play()` of `HLSPlayer`.
private final class SeekRecordingPlayer: HLSPlayer, @unchecked Sendable {
    private(set) nonisolated(unsafe) var seekTimes: [CMTime] = []

    override nonisolated func seek(to time: CMTime) { seekTimes.append(time) }
}
