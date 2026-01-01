//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideoSwiftUI
import XCTest

final class ParticipantsSpotlightLayout_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var call = streamVideoUI?.streamVideo.call(callType: callType, callId: callId)
    
    @MainActor
    func test_spotlight_participantWithAudio_snapshot() {
        for count in spotlightParticipants {
            let participants = ParticipantFactory.get(count, withAudio: true)
            let layout = ParticipantsSpotlightLayout(
                viewFactory: DefaultViewFactory.shared,
                participant: participants.first!,
                call: call,
                participants: participants,
                frame: .init(origin: .zero, size: defaultScreenSize),
                onChangeTrackVisibility: { _, _ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
    
    @MainActor
    func test_spotlight_participantWithoutAudio_snapshot() {
        for count in spotlightParticipants {
            let participants = ParticipantFactory.get(count, withAudio: false)
            let layout = ParticipantsSpotlightLayout(
                viewFactory: DefaultViewFactory.shared,
                participant: participants.first!,
                call: call,
                participants: participants,
                frame: .init(origin: .zero, size: defaultScreenSize),
                onChangeTrackVisibility: { _, _ in }
            )
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "with_\(count)_participants")
        }
    }
    
    @MainActor
    func test_spotlight_participantsConnectionQuality_snapshot() throws {
        for quality in connectionQuality {
            let participants = ParticipantFactory.get(spotlightParticipants.last!, connectionQuality: quality)
            let layout = ParticipantsSpotlightLayout(
                viewFactory: DefaultViewFactory.shared,
                participant: participants.first!,
                call: call,
                participants: participants,
                frame: .init(origin: .zero, size: defaultScreenSize),
                onChangeTrackVisibility: { _, _ in }
            )
            
            AssertSnapshot(layout, variants: snapshotVariants, suffix: "\(quality)")
        }
    }
    
    @MainActor
    func test_spotlight_participantsSpeaking_snapshot() {
        let participants = ParticipantFactory.get(spotlightParticipants.last!, speaking: true)
        let layout = ParticipantsSpotlightLayout(
            viewFactory: DefaultViewFactory.shared,
            participant: participants.first!,
            call: call,
            participants: participants,
            frame: .init(origin: .zero, size: defaultScreenSize),
            onChangeTrackVisibility: { _, _ in }
        )
        AssertSnapshot(layout, variants: snapshotVariants)
    }
}
