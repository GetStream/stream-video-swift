//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamSwiftTestHelpers
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
    
    func test_grid_participantWithAudio_snapshot() {
        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: DefaultViewFactory.shared,
                call: call,
                participants: ParticipantFactory.get(count, withAudio: true),
                availableFrame: .init(origin: .zero, size: defaultScreenSize),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
    
    func test_grid_participantWithoutAudio_snapshot() {
        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: DefaultViewFactory.shared,
                call: call,
                participants: ParticipantFactory.get(count, withAudio: false),
                availableFrame: .init(origin: .zero, size: defaultScreenSize),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
    
    func test_grid_participantsConnectionQuality_snapshot() throws {
        for quality in connectionQuality {
            let count = gridParticipants.last!
            let layout = ParticipantsGridLayout(
                viewFactory: DefaultViewFactory.shared,
                call: call,
                participants: ParticipantFactory.get(count, connectionQuality: quality),
                availableFrame: .init(origin: .zero, size: defaultScreenSize),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "\(quality)")
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
                viewFactory: DefaultViewFactory.shared,
                call: call,
                participants: participants,
                availableFrame: .init(origin: .zero, size: defaultScreenSize),
                orientation: .portrait,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
}
