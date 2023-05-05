//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest

@MainActor
final class ParticipantsSpotlightLayout_Tests: StreamVideoUITestCase {
    
    func test_spotlight_participantWithAudio_snapshot() {
        for count in spotlightParticipants {
            let participants = ParticipantFactory.get(count, withAudio: true)
            let layout = ParticipantsSpotlightLayout(
                viewFactory: TestViewFactory(),
                participant: participants.first!,
                participants: participants,
                size: defaultScreenSize,
                pinnedParticipant: .constant(nil),
                onViewRendering: {_,_ in },
                onChangeTrackVisibility: {_,_ in }
            )
            
            AssertSnapshot(layout, suffix: "with_\(count)_participants")
        }
    }
    
    func test_spotlight_participantWithoutAudio_snapshot() {
        for count in spotlightParticipants {
            let participants = ParticipantFactory.get(count, withAudio: false)
            let layout = ParticipantsSpotlightLayout(
                viewFactory: TestViewFactory(),
                participant: participants.first!,
                participants: participants,
                size: defaultScreenSize,
                pinnedParticipant: .constant(nil),
                onViewRendering: {_,_ in },
                onChangeTrackVisibility: {_,_ in }
            )
            
            AssertSnapshot(layout, suffix: "with_\(count)_participants")
        }
    }
    
    func test_spotlight_participantsConnectionQuality_snapshot() throws {
        for quality in connectionQuality {
            let participants = ParticipantFactory.get(spotlightParticipants.last!, connectionQuality: quality)
            let layout = ParticipantsSpotlightLayout(
                viewFactory: TestViewFactory(),
                participant: participants.first!,
                participants: participants,
                size: defaultScreenSize,
                pinnedParticipant: .constant(nil),
                onViewRendering: {_,_ in },
                onChangeTrackVisibility: {_,_ in }
            )
            
            AssertSnapshot(layout, suffix: "\(quality)")
        }
    }
    
    func test_spotlight_participantsSpeaking_snapshot() {
        let participants = ParticipantFactory.get(spotlightParticipants.last!, speaking: true)
        let layout = ParticipantsSpotlightLayout(
            viewFactory: TestViewFactory(),
            participant: participants.first!,
            participants: participants,
            size: defaultScreenSize,
            pinnedParticipant: .constant(nil),
            onViewRendering: {_,_ in },
            onChangeTrackVisibility: {_,_ in }
        )
        
        AssertSnapshot(layout)
    }
}
