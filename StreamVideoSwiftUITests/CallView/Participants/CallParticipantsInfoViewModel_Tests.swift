//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class CallParticipantsInfoViewModel_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var images: Images! = .init()
    private lazy var call: Call! = streamVideoUI?.streamVideo.call(
        callType: callType,
        callId: callId
    )
    private lazy var subject: CallParticipantsInfoViewModel! = .init(call: call)

    override func setUp() async throws {
        try await super.setUp()
        images.participantMuteAudio = Image(systemName: "a.circle")
        images.participantMuteVideo = Image(systemName: "b.circle")
        images.participantBlock = Image(systemName: "c.circle")
        images.participantUnblock = Image(systemName: "d.circle")
        InjectedValues[\.videoAppearance] = VideoAppearance(images: images)
        call.state.ownCapabilities = [.blockUsers]
    }

    override func tearDown() async throws {
        InjectedValues[\.videoAppearance] = .shared
        subject = nil
        call = nil
        images = nil
        try await super.tearDown()
    }

    // MARK: - menuActions

    func test_menuActions_participantWithAudioAndVideo_usesVideoAppearanceIcons() {
        let participant = ParticipantFactory.get(1, withVideo: true, withAudio: true)[0]

        let icons = subject.menuActions(for: participant).map(\.icon)

        XCTAssertEqual(
            icons,
            [images.participantMuteAudio, images.participantMuteVideo, images.participantBlock]
        )
    }

    // MARK: - unblockActions

    func test_unblockActions_usesVideoAppearanceIcon() {
        let icons = subject.unblockActions(for: User(id: "blocked")).map(\.icon)

        XCTAssertEqual(icons, [images.participantUnblock])
    }
}
