//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class PictureInPictureParticipantModifierTests: StreamVideoUITestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()

    override func tearDown() async throws {
        mockStreamVideo = nil
        try await super.tearDown()
    }

    func test_modifier_participant_hasVideoFalse_hasAudioFalse() {
        AssertSnapshot(
            makeView(hasAudio: false, hasVideo: false),
            variants: snapshotVariants,
            size: .init(width: 250, height: 100)
        )
    }

    func test_modifier_participant_hasVideoTrue_hasAudioFalse() {
        AssertSnapshot(
            makeView(hasAudio: true, hasVideo: false),
            variants: snapshotVariants,
            size: .init(width: 250, height: 100)
        )
    }

    func test_modifier_participant_hasVideoFalse_hasAudioTrue() {
        AssertSnapshot(
            makeView(hasAudio: false, hasVideo: true),
            variants: snapshotVariants,
            size: .init(width: 250, height: 100)
        )
    }

    func test_modifier_participant_hasVideoTrue_hasAudioTrue() {
        AssertSnapshot(
            makeView(hasAudio: true, hasVideo: true),
            variants: snapshotVariants,
            size: .init(width: 250, height: 100)
        )
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func makeView(
        hasAudio: Bool,
        hasVideo: Bool
    ) -> some View {
        Color
            .red
            .pictureInPictureParticipant(
                participant: .dummy(
                    name: "Get Stream",
                    hasVideo: hasVideo,
                    hasAudio: hasAudio
                ),
                call: MockCall(.dummy())
            )
            .frame(width: 250, height: 100)
    }
}
