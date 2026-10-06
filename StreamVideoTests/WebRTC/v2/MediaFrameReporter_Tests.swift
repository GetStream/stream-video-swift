//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class MediaFrameReporter_Tests: XCTestCase, @unchecked Sendable {

    private enum Retirement {
        case remove, removeAll, reset, resetSameTrack, readdSameTrack
    }

    func test_reportFrame_removedAudioTrack_doesNotReport() async throws {
        try await assertRetiredFrameIsIgnored(type: .audio, retirement: .remove)
    }

    func test_reportFrame_removedVideoTrack_doesNotReport() async throws {
        try await assertRetiredFrameIsIgnored(type: .video, retirement: .remove)
    }

    func test_reportFrame_removeAll_oldAudioFrameDoesNotReport() async throws {
        try await assertRetiredFrameIsIgnored(type: .audio, retirement: .removeAll)
    }

    func test_reportFrame_removeAll_oldVideoFrameDoesNotReport() async throws {
        try await assertRetiredFrameIsIgnored(type: .video, retirement: .removeAll)
    }

    func test_reportFrame_reset_oldAudioFrameDoesNotConsumeNewJoin() async throws {
        try await assertRetiredFrameIsIgnored(type: .audio, retirement: .reset)
    }

    func test_reportFrame_reset_oldVideoFrameDoesNotConsumeNewJoin() async throws {
        try await assertRetiredFrameIsIgnored(type: .video, retirement: .reset)
    }

    func test_reportFrame_resetWithSameAudioTrack_ignoresPreviousRegistration() async throws {
        try await assertRetiredFrameIsIgnored(type: .audio, retirement: .resetSameTrack)
    }

    func test_reportFrame_resetWithSameVideoTrack_ignoresPreviousRegistration() async throws {
        try await assertRetiredFrameIsIgnored(type: .video, retirement: .resetSameTrack)
    }

    func test_reportFrame_readdedAudioTrack_ignoresPreviousRegistration() async throws {
        try await assertRetiredFrameIsIgnored(type: .audio, retirement: .readdSameTrack)
    }

    func test_reportFrame_readdedVideoTrack_ignoresPreviousRegistration() async throws {
        try await assertRetiredFrameIsIgnored(type: .video, retirement: .readdSameTrack)
    }

    private func assertRetiredFrameIsIgnored(
        type: TrackType,
        retirement: Retirement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let factory = PeerConnectionFactory.mock()
        let oldTrack: RTCMediaStreamTrack = type == .audio
            ? factory.mockAudioTrack()
            : factory.mockVideoTrack(forScreenShare: false)
        let eventReporter = MockClientEventReporter()
        let subject = MediaFrameReporter(clientEventReporter: eventReporter)
        let sessionID = String.unique
        await subject.reset(details: .init(callSessionId: .unique))
        let oldRenderer = try await captureFrameRenderer(track: oldTrack, type: type, reporter: subject)
        var currentTrack: RTCMediaStreamTrack?
        var currentRenderer: MediaFrameTrackRenderer?

        switch retirement {
        case .remove:
            await subject.remove(oldTrack, type: type)
        case .removeAll:
            await subject.removeAllTracks()
        case .reset, .resetSameTrack:
            await subject.reset(details: .init(callSessionId: sessionID))
            currentTrack = retirement == .resetSameTrack ? oldTrack : (type == .audio
                ? factory.mockAudioTrack()
                : factory.mockVideoTrack(forScreenShare: false)
            )
        case .readdSameTrack:
            await subject.remove(oldTrack, type: type)
            currentTrack = oldTrack
        }
        if let currentTrack {
            currentRenderer = try await captureFrameRenderer(track: currentTrack, type: type, reporter: subject)
        }

        await oldRenderer.reportFrame()
        let staleEvents = await eventReporter.reportedEvents
        XCTAssertTrue(staleEvents.isEmpty, "A retired renderer reported a frame.", file: file, line: line)
        if let currentRenderer, let currentTrack {
            await currentRenderer.reportFrame()
            await currentRenderer.reportFrame()
            let events = await eventReporter.reportedEvents
            XCTAssertEqual(events.count, 1, file: file, line: line)
            XCTAssertEqual(events.first?.stage, type == .audio ? .firstAudioFrame : .firstVideoFrame, file: file, line: line)
            XCTAssertEqual(events.first?.details.trackId, currentTrack.trackId, file: file, line: line)
            if retirement != .readdSameTrack {
                XCTAssertEqual(events.first?.details.callSessionId, sessionID, file: file, line: line)
            }
        }
        await subject.removeAllTracks()
    }
}
