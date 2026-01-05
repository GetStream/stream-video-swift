//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

@MainActor
final class PictureInPictureTrackStateAdapterTests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var factory: PeerConnectionFactory! = .build(audioProcessingModule: MockAudioProcessingModule.shared)
    private lazy var store: PictureInPictureStore! = .init()
    private lazy var mockCall: MockCall! = .init()
    private lazy var subject: PictureInPictureTrackStateAdapter! = .init(store: store)

    private lazy var participantA: CallParticipant! = CallParticipant.dummy(
        track: factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
    )
    private lazy var participantB: CallParticipant! = CallParticipant.dummy(
        track: factory.makeVideoTrack(source: factory.makeVideoSource(forScreenShare: false))
    )

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        _ = subject
        store.dispatch(.setCall(mockCall))
        await wait(for: 1.0)
    }

    override func tearDown() async throws {
        participantA.track?.isEnabled = false
        participantB.track?.isEnabled = false
        subject = nil
        factory = nil
        participantA = nil
        participantB = nil
        mockStreamVideo = nil
        mockCall = nil
        try await super.tearDown()
    }

    // MARK: - didUpdateActive

    func test_isActive_transitionFromTrueToFalse_allStoredTracksShouldBecomeEnabled() async throws {
        mockCall.state.participantsMap = [
            participantA.sessionId: participantA,
            participantB.sessionId: participantB
        ]
        store.dispatch(.setActive(true))
        await fulfilmentInMainActor { self.store.state.isActive }

        participantA.track?.isEnabled = false
        participantB.track?.isEnabled = false
        store.dispatch(.setActive(false))

        await fulfilmentInMainActor { self.store.state.isActive == false }
        await fulfilmentInMainActor {
            self.participantA.track?.isEnabled == true && self.participantB.track?.isEnabled == true
        }
    }

    // MARK: - didUpdateContent

    func test_content_isActiveFalse_noTrackShouldBeDisabled() async throws {
        store.dispatch(.setContent(.participant(mockCall, participantA, participantA.track)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .participant(_, participant, _):
                return participant == self.participantA
            default:
                return false
            }
        }
        store.dispatch(.setContent(.participant(mockCall, participantB, participantB.track)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .participant(_, participant, _):
                return participant == self.participantB
            default:
                return false
            }
        }
        XCTAssertTrue(participantA.track?.isEnabled ?? false)
        XCTAssertTrue(participantB.track?.isEnabled ?? false)
    }

    func test_content_isActiveTrue_contentIsParticipant_newTrackShouldBeEnabled() async throws {
        store.dispatch(.setActive(true))
        participantB.track?.isEnabled = false
        store.dispatch(.setContent(.participant(mockCall, participantA, participantA.track)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .participant(_, participant, _):
                return participant == self.participantA
            default:
                return false
            }
        }
        store.dispatch(.setContent(.participant(mockCall, participantB, participantB.track)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .participant(_, participant, _):
                return participant == self.participantB
            default:
                return false
            }
        }
        XCTAssertFalse(participantA.track?.isEnabled ?? true)
        XCTAssertTrue(participantB.track?.isEnabled ?? false)
    }

    func test_content_isActiveTrue_contentIsParticipant_oldTrackShouldBeDisabled() async throws {
        store.dispatch(.setActive(true))
        store.dispatch(.setContent(.participant(mockCall, participantA, participantA.track)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .participant(_, participant, _):
                return participant == self.participantA
            default:
                return false
            }
        }
        store.dispatch(.setContent(.participant(mockCall, participantB, participantB.track)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .participant(_, participant, _):
                return participant == self.participantB
            default:
                return false
            }
        }
        XCTAssertFalse(participantA.track?.isEnabled ?? true)
        XCTAssertTrue(participantB.track?.isEnabled ?? false)
    }

    func test_content_isActiveTrue_contentIsScreenSharing_oldTrackShouldBeDisabled() async throws {
        store.dispatch(.setActive(true))
        store.dispatch(.setContent(.screenSharing(mockCall, participantA, participantA.track!)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .screenSharing(_, participant, _):
                return participant == self.participantA
            default:
                return false
            }
        }
        store.dispatch(.setContent(.participant(mockCall, participantB, participantB.track)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .participant(_, participant, _):
                return participant == self.participantB
            default:
                return false
            }
        }
        XCTAssertFalse(participantA.track?.isEnabled ?? true)
        XCTAssertTrue(participantB.track?.isEnabled ?? false)
    }

    func test_content_isActiveTrue_contentTrackWasNotChanged_trackShouldRemainEnabled() async throws {
        store.dispatch(.setActive(true))
        store.dispatch(.setContent(.screenSharing(mockCall, participantA, participantA.track!)))

        await fulfilmentInMainActor {
            switch self.store.state.content {
            case let .screenSharing(_, participant, _):
                return participant == self.participantA
            default:
                return false
            }
        }
        store.dispatch(.setContent(.screenSharing(mockCall, participantA, participantA.track!)))

        await wait(for: 0.5)
        XCTAssertTrue(participantA.track?.isEnabled ?? false)
    }
}
