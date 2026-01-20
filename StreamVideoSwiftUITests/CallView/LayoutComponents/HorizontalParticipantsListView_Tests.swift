//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class HorizontalParticipantsListView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    func test_layout_participantsWithAudio_withoutAllInfo_viewWasConfiguredCorrectly() {
        assertLayout(participantsCount: 10, withAudio: true, showAllInfo: false)
    }

    func test_layout_participantsWithoutAudio_withoutAllInfo_viewWasConfiguredCorrectly() {
        assertLayout(participantsCount: 10, withAudio: false, showAllInfo: false)
    }

    func test_layout_participantsWithAudio_withAllInfo_viewWasConfiguredCorrectly() {
        assertLayout(participantsCount: 10, withAudio: true, showAllInfo: true)
    }

    func test_layout_participantsWithoutAudio_withAllInfo_viewWasConfiguredCorrectly() {
        assertLayout(participantsCount: 10, withAudio: false, showAllInfo: true)
    }

    func test_layout_participantsWithAudio_withAllInfoAndSmallerSize_viewWasConfiguredCorrectly() {
        assertLayout(participantsCount: 10, withAudio: true, showAllInfo: true, thumbnailSize: 120)
    }

    func test_layout_participantsWithoutAudio_withAllInfoAndSmallerSize_viewWasConfiguredCorrectly() {
        assertLayout(participantsCount: 10, withAudio: false, showAllInfo: true, thumbnailSize: 120)
    }

    private func assertLayout(
        participantsCount: Int,
        withAudio: Bool = true,
        showAllInfo: Bool = false,
        thumbnailSize: CGFloat = 240,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        let screenWidth: CGFloat = 375
        let call = streamVideoUI?.streamVideo.call(callType: callType, callId: callId)
        let participants = ParticipantFactory.get(participantsCount, withAudio: true)

        AssertSnapshot(
            HorizontalParticipantsListView(
                viewFactory: DefaultViewFactory.shared,
                participants: participants,
                frame: .init(origin: .zero, size: .init(width: screenWidth, height: thumbnailSize)),
                call: call,
                showAllInfo: showAllInfo
            ).frame(width: screenWidth),
            variants: snapshotVariants,
            size: .zero,
            line: line,
            file: file,
            function: function
        )
    }
}
