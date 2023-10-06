//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest

@MainActor
final class ParticipantsGridLayout_Tests: StreamVideoUITestCase {
    
    nonisolated private lazy var callController = CallController_Mock(
        defaultAPI: DefaultAPI(
            basePath: "test.com",
            transport: httpClient as! HTTPClient_Mock,
            middlewares: []
        ),
        user: StreamVideo.mockUser,
        callId: callId,
        callType: callType,
        apiKey: "123",
        videoConfig: VideoConfig(),
        cachedLocation: nil
    )
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let streamVideo = StreamVideo.mock(httpClient: httpClient, callController: callController)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
    }
    
    private lazy var call = streamVideoUI?.streamVideo.call(callType: callType, callId: callId)
    
    private func gridSize(for participantsCount: Int) -> CGRect {
        let heightDivider = CGFloat((participantsCount == 2 || participantsCount == 3) ? participantsCount : 1)
        return .init(origin: .zero, size: CGSize(width: defaultScreenSize.width, height: defaultScreenSize.height / heightDivider))
    }
    
    func test_grid_participantWithAudio_snapshot() {
        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: TestViewFactory(participantLayout: .grid, participantsCount: count),
                call: call,
                participants: ParticipantFactory.get(count, withAudio: true),
                availableFrame: gridSize(for: count),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "with_\(count)_participants")
        }
    }
    
    func test_grid_participantWithoutAudio_snapshot() {
        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: TestViewFactory(participantLayout: .grid, participantsCount: count),
                call: call,
                participants: ParticipantFactory.get(count, withAudio: false),
                availableFrame: gridSize(for: count),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "with_\(count)_participants")
        }
    }
    
    func test_grid_participantsConnectionQuality_snapshot() throws {
        for quality in connectionQuality {
            let count = gridParticipants.last!
            let layout = ParticipantsGridLayout(
                viewFactory: TestViewFactory(participantLayout: .grid, participantsCount: count),
                call: call,
                participants: ParticipantFactory.get(count, connectionQuality: quality),
                availableFrame: gridSize(for: count),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "\(quality)")
        }
    }
    
    func test_grid_participantsSpeaking_snapshot() {
        for count in gridParticipants {
            let participants = ParticipantFactory.get(count, speaking: true)
            var dict = [String: CallParticipant]()
            for participant in participants {
                dict[participant.id] = participant
            }
            callController.update(participants: dict)
            let layout = ParticipantsGridLayout(
                viewFactory: TestViewFactory(participantLayout: .grid, participantsCount: count),
                call: call,
                participants: participants,
                availableFrame: gridSize(for: count),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "with_\(count)_participants")
        }
    }
}
