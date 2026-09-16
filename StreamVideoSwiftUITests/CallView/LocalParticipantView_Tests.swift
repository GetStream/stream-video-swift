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

    // MARK: - Connection Quality

    func test_localParticipantView_connectionQualityExcellent_snapshot() {
        let view = makeView(
            audioOn: true,
            showAllInfo: true,
            connectionQuality: .excellent
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }

    func test_localParticipantView_connectionQualityGood_snapshot() {
        let view = makeView(
            audioOn: true,
            showAllInfo: true,
            connectionQuality: .good
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }

    func test_localParticipantView_connectionQualityPoor_snapshot() {
        let view = makeView(
            audioOn: true,
            showAllInfo: true,
            connectionQuality: .poor
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }

    // MARK: - Helpers

    private func makeView(
        audioOn: Bool,
        showAllInfo: Bool = false,
        connectionQuality: ConnectionQuality = .excellent
    ) -> some View {
        let participant = ParticipantFactory.get(
            1,
            withVideo: true,
            withAudio: audioOn,
            connectionQuality: connectionQuality
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
                callSettings: .constant(settings),
                showAllInfo: showAllInfo
            )
        )
        .frame(
            width: viewSize.width,
            height: viewSize.height
        )
    }
}
