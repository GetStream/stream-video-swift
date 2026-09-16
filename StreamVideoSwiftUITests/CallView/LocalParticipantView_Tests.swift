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

    override func tearDown() async throws {
        call = nil
        try await super.tearDown()
    }

    func test_localParticipantView_snapshot() {
        let participant = ParticipantFactory.get(
            1,
            withVideo: true,
            withAudio: true
        ).first!

        let view = LocalVideoView(
            viewFactory: TestViewFactory(),
            participant: participant,
            callSettings: CallSettings(),
            call: call,
            availableFrame: .init(
                origin: .zero,
                size: .init(width: 120, height: 120)
            )
        )
        .modifier(
            LocalParticipantViewModifier(
                localParticipant: participant,
                call: call,
                callSettings: .constant(CallSettings())
            )
        )
        .frame(width: 120, height: 120)

        AssertSnapshot(
            view,
            variants: snapshotVariants
        )
    }

    func test_localParticipantView_micOff_snapshot() {
        let participant = ParticipantFactory.get(
            1,
            withVideo: true,
            withAudio: false
        ).first!

        let view = LocalVideoView(
            viewFactory: TestViewFactory(),
            participant: participant,
            callSettings: CallSettings(audioOn: false),
            call: call,
            availableFrame: .init(
                origin: .zero,
                size: .init(width: 120, height: 120)
            )
        )
        .modifier(
            LocalParticipantViewModifier(
                localParticipant: participant,
                call: call,
                callSettings: .constant(
                    CallSettings(audioOn: false)
                )
            )
        )
        .frame(width: 120, height: 120)

        AssertSnapshot(
            view,
            variants: snapshotVariants
        )
    }
}
