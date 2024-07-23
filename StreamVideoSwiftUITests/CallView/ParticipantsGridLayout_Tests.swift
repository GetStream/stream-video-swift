//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class ParticipantsGridLayout_Tests: StreamVideoUITestCase {
    
    private var mockedOrientation: StreamDeviceOrientation! = .portrait
    private lazy var orientationAdapter: StreamDeviceOrientationAdapter! = .init { self.mockedOrientation }

    private lazy var callController: CallController_Mock! = CallController_Mock(
        defaultAPI: DefaultAPI(
            basePath: "test.com",
            transport: httpClient as! HTTPClient_Mock,
            middlewares: []
        ),
        user: StreamVideo.mockUser,
        callId: callId,
        callType: callType,
        apiKey: "123",
        videoConfig: .dummy(),
        cachedLocation: nil
    )

    @MainActor
    override func setUp() {
        super.setUp()
        let streamVideo = StreamVideo.mock(httpClient: httpClient, callController: callController)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
        InjectedValues[\.orientationAdapter] = orientationAdapter
    }

    @MainActor
    override func tearDown() {
        mockedOrientation = nil
        orientationAdapter = nil
        callController = nil
        super.tearDown()
    }

    private lazy var call = streamVideoUI?.streamVideo.call(callType: callType, callId: callId)
    
    @MainActor
    func test_grid_participantWithAudio_snapshot() {
        mockedOrientation = .portrait

        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: DefaultViewFactory.shared,
                call: call,
                participants: ParticipantFactory.get(count, withAudio: true),
                availableFrame: .init(origin: .zero, size: defaultScreenSize),
                onChangeTrackVisibility: { _, _ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
    
    @MainActor
    func test_grid_participantWithoutAudio_snapshot() {
        mockedOrientation = .portrait

        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: DefaultViewFactory.shared,
                call: call,
                participants: ParticipantFactory.get(count, withAudio: false),
                availableFrame: .init(origin: .zero, size: defaultScreenSize),
                onChangeTrackVisibility: { _, _ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
    
    @MainActor
    func test_grid_participantsConnectionQuality_snapshot() throws {
        mockedOrientation = .portrait

        for quality in connectionQuality {
            let count = gridParticipants.last!
            let layout = ParticipantsGridLayout(
                viewFactory: DefaultViewFactory.shared,
                call: call,
                participants: ParticipantFactory.get(count, connectionQuality: quality),
                availableFrame: .init(origin: .zero, size: defaultScreenSize),
                onChangeTrackVisibility: { _, _ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "\(quality)")
        }
    }
    
    @MainActor
    func test_grid_participantsSpeaking_snapshot() {
        mockedOrientation = .portrait

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
                onChangeTrackVisibility: { _, _ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
}
