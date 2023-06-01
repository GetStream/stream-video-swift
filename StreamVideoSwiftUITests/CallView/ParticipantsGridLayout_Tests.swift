//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
import SnapshotTesting
import XCTest

@MainActor
final class ParticipantsGridLayout_Tests: StreamVideoUITestCase {
    
    private func gridSize(for participantsCount: Int) -> CGSize {
        let heightDivider = CGFloat((participantsCount == 2 || participantsCount == 3) ? participantsCount : 1)
        return CGSize(width: defaultScreenSize.width, height: defaultScreenSize.height / heightDivider)
    }
    
    func test_grid_participantWithAudio_snapshot() {
        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: TestViewFactory(participantLayout: .grid, participantsCount: count),
                participants: ParticipantFactory.get(count, withAudio: true),
                pinnedParticipant: .constant(nil),
                availableSize: gridSize(for: count),
                orientation: .portrait,
                onViewRendering: {_,_ in },
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "with_\(count)_participants")
        }
    }
    
    func test_grid_participantWithoutAudio_snapshot() {
        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: TestViewFactory(participantLayout: .grid, participantsCount: count),
                participants: ParticipantFactory.get(count, withAudio: false),
                pinnedParticipant: .constant(nil),
                availableSize: gridSize(for: count),
                orientation: .portrait,
                onViewRendering: {_,_ in },
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
                participants: ParticipantFactory.get(count, connectionQuality: quality),
                pinnedParticipant: .constant(nil),
                availableSize: gridSize(for: count),
                orientation: .portrait,
                onViewRendering: {_,_ in },
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "\(quality)")
        }
    }
    
    func test_grid_participantsSpeaking_snapshot() {
        for count in gridParticipants {
            let layout = ParticipantsGridLayout(
                viewFactory: TestViewFactory(participantLayout: .grid, participantsCount: count),
                participants: ParticipantFactory.get(count, speaking: true),
                pinnedParticipant: .constant(nil),
                availableSize: gridSize(for: count),
                orientation: .portrait,
                onViewRendering: {_,_ in },
                onChangeTrackVisibility: {_,_ in }
            )
            AssertSnapshot(layout, suffix: "with_\(count)_participants")
        }
    }
}
