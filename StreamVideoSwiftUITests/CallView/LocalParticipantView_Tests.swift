//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class LocalParticipantView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var call = streamVideoUI?.streamVideo
        .call(callType: callType, callId: callId)

    private let viewSize = CGSize(width: 120, height: 160)

    override func tearDown() async throws {
        call = nil
        try await super.tearDown()
    }

    // MARK: - Mic On

    func test_localParticipantView_snapshot() {
        let view = makeView(audioOn: true)
        AssertSnapshot(view, variants: snapshotVariants)
    }

    func test_localParticipantView_extraExtraExtraLarge_snapshot() {
        let view = makeView(audioOn: true)
        AssertSnapshot(
            view,
            variants: [.extraExtraExtraLargeLight]
        )
    }

    // MARK: - Mic Off

    func test_localParticipantView_micOff_snapshot() {
        let view = makeView(audioOn: false)
        AssertSnapshot(view, variants: snapshotVariants)
    }

    func test_localParticipantView_micOff_extraExtraExtraLarge_snapshot() {
        let view = makeView(audioOn: false)
        AssertSnapshot(
            view,
            variants: [.extraExtraExtraLargeLight]
        )
    }

    // MARK: - Helpers

    private func makeView(audioOn: Bool) -> some View {
        let participant = ParticipantFactory.get(
            1,
            withVideo: true,
            withAudio: audioOn
        ).first!

        let settings = CallSettings(audioOn: audioOn)

        return LocalVideoView(
            viewFactory: TestViewFactory(),
            participant: participant,
            callSettings: settings,
            call: call,
            availableFrame: .init(
                origin: .zero,
                size: viewSize
            )
        )
        .modifier(
            LocalParticipantViewModifier(
                localParticipant: participant,
                call: call,
                callSettings: .constant(settings)
            )
        )
        .frame(
            width: viewSize.width,
            height: viewSize.height
        )
    }
}
