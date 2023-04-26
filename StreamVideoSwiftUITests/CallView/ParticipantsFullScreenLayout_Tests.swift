//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest

@MainActor
final class ParticipantsFullScreenLayout_Tests: StreamVideoUITestCase {
    
    func test_fullscreen_participantWithAudio_snapshot() throws {
        let layout = ParticipantsFullScreenLayout(
            viewFactory: TestViewFactory(),
            participant: ParticipantFactory.get(1, withAudio: true).first!,
            size: defaultScreenSize,
            pinnedParticipant: .constant(nil),
            onViewRendering: {_,_ in },
            onChangeTrackVisibility: {_,_ in }
        )
        
        AssertSnapshot(layout)
    }
    
    func test_fullscreen_participantWithoutAudio_snapshot() throws {
        let layout = ParticipantsFullScreenLayout(
            viewFactory: TestViewFactory(),
            participant: ParticipantFactory.get(1, withAudio: false).first!,
            size: defaultScreenSize,
            pinnedParticipant: .constant(nil),
            onViewRendering: {_,_ in },
            onChangeTrackVisibility: {_,_ in }
        )
        
        AssertSnapshot(layout)
    }
    
    func test_fullscreen_participantConnectionQuality_snapshot() throws {
        for quality in connectionQuality {
            let layout = ParticipantsFullScreenLayout(
                viewFactory: TestViewFactory(),
                participant: ParticipantFactory.get(1, connectionQuality: quality).first!,
                size: defaultScreenSize,
                pinnedParticipant: .constant(nil),
                onViewRendering: {_,_ in },
                onChangeTrackVisibility: {_,_ in }
            )
            
            AssertSnapshot(layout, suffix: "\(quality)")
        }
    }
    
    func test_fullscreen_participantSpeaking_snapshot() throws {
        let layout = ParticipantsFullScreenLayout(
            viewFactory: TestViewFactory(),
            participant: ParticipantFactory.get(1, withAudio: true, speaking: true).first!,
            size: defaultScreenSize,
            pinnedParticipant: .constant(nil),
            onViewRendering: {_,_ in },
            onChangeTrackVisibility: {_,_ in }
        )
        
        AssertSnapshot(layout)
    }
}
