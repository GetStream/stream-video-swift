//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest

@MainActor
final class ParticipantsFullScreenLayout_Tests: StreamVideoUITestCase {
    
    private lazy var call = streamVideoUI?.streamVideo.call(callType: callType, callId: callId)
    
    func test_fullscreen_participantWithAudio_snapshot() throws {
        let layout = ParticipantsFullScreenLayout(
            viewFactory: TestViewFactory(),
            participant: ParticipantFactory.get(1, withAudio: true).first!,
            call: call,
            size: defaultScreenSize,
            onChangeTrackVisibility: {_,_ in }
        )
        AssertSnapshot(layout)
    }
    
    func test_fullscreen_participantWithoutAudio_snapshot() throws {
        let layout = ParticipantsFullScreenLayout(
            viewFactory: TestViewFactory(),
            participant: ParticipantFactory.get(1, withAudio: false).first!,
            call: call,
            size: defaultScreenSize,
            onChangeTrackVisibility: {_,_ in }
        )
        AssertSnapshot(layout)
    }
    
    func test_fullscreen_participantConnectionQuality_snapshot() throws {
        for quality in connectionQuality {
            let layout = ParticipantsFullScreenLayout(
                viewFactory: TestViewFactory(),
                participant: ParticipantFactory.get(1, connectionQuality: quality).first!,
                call: call,
                size: defaultScreenSize,
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "\(quality)")
        }
    }
    
    func test_fullscreen_participantSpeaking_snapshot() throws {
        let layout = ParticipantsFullScreenLayout(
            viewFactory: TestViewFactory(),
            participant: ParticipantFactory.get(1, withAudio: true, speaking: true).first!,
            call: call,
            size: defaultScreenSize,
            onChangeTrackVisibility: {_,_ in }
        )
        AssertSnapshot(layout)
    }
}
