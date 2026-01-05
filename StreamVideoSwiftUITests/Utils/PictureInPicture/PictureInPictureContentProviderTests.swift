//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

@MainActor
final class PictureInPictureContentProviderTests: XCTestCase, @unchecked Sendable {

    private nonisolated(unsafe) static var videoConfig: VideoConfig! = .dummy()

    private var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var store: PictureInPictureStore! = .init()
    private lazy var mockPeerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var subject: PictureInPictureContentProvider! = .init(store: store)

    override func setUp() async throws {
        try await super.setUp()
        _ = subject
    }

    override func tearDown() async throws {
        store = nil
        mockPeerConnectionFactory = nil
        mockStreamVideo = nil
        subject = nil
        try await super.tearDown()
    }

    override class func tearDown() {
        Self.videoConfig = nil
        super.tearDown()
    }

    // MARK: - reconnectionStatus

    func test_reconnectionStatusUpdatesToReconnecting_contentUpdates() async throws {
        try await assertContentUpdate { call in
            call.state.reconnectionStatus = .reconnecting
        } validation: {
            $0 == .reconnecting
        }
    }

    // MARK: - internetConnection

    func test_internetConnectionDrops_contentUpdates() async throws {
        let mockInternetConnection = MockInternetConnection()
        InternetConnection.currentValue = mockInternetConnection

        try await assertContentUpdate { _ in
            mockInternetConnection.subject.send(.unavailable)
        } validation: {
            $0 == .reconnecting
        }
    }

    // MARK: - Participants Updates

    func test_participantsUpdates_screenSharingActive_currentUserNotScreenSharing_contentUpdates() async throws {
        let videoTrack = RTCMediaStreamTrack.dummy(
            kind: .video,
            peerConnectionFactory: mockPeerConnectionFactory
        ) as? RTCVideoTrack
        let participant = CallParticipant.dummy(
            isScreenSharing: true,
            screenshareTrack: videoTrack
        )
        try await assertContentUpdate {
            $0.state.participantsMap = [participant.sessionId: participant]
        } validation: {
            switch $0 {
            case let .screenSharing(_, contentParticipant, track):
                return participant == contentParticipant && track.trackId == videoTrack?.trackId
            default:
                return false
            }
        }
    }

    func test_participantsUpdates_screenSharingInactive_dominantSpeakerWithTrack_contentUpdates() async throws {
        let videoTrack = RTCMediaStreamTrack.dummy(
            kind: .video,
            peerConnectionFactory: mockPeerConnectionFactory
        ) as? RTCVideoTrack
        let participant = CallParticipant.dummy(
            hasVideo: true,
            track: videoTrack,
            isDominantSpeaker: true
        )
        try await assertContentUpdate {
            $0.state.participants = [participant]
        } validation: {
            switch $0 {
            case let .participant(_, contentParticipant, track):
                return participant == contentParticipant && track?.trackId == videoTrack?.trackId
            default:
                return false
            }
        }
    }

    func test_participantsUpdates_screenSharingInactive_dominantSpeakerWithoutTrack_contentUpdates() async throws {
        let participant = CallParticipant.dummy(
            isDominantSpeaker: true
        )
        try await assertContentUpdate {
            $0.state.participants = [participant]
        } validation: {
            switch $0 {
            case let .participant(_, contentParticipant, _):
                return participant == contentParticipant
            default:
                return false
            }
        }
    }

    func test_participantsUpdates_screenSharingInactive_otherUserWithVideoAndTrack_contentUpdates() async throws {
        let videoTrack = RTCMediaStreamTrack.dummy(
            kind: .video,
            peerConnectionFactory: mockPeerConnectionFactory
        ) as? RTCVideoTrack
        let participant = CallParticipant.dummy(
            hasVideo: true,
            track: videoTrack
        )
        try await assertContentUpdate {
            $0.state.participants = [participant]
        } validation: {
            switch $0 {
            case let .participant(_, contentParticipant, track):
                return participant == contentParticipant && track?.trackId == videoTrack?.trackId
            default:
                return false
            }
        }
    }

    func test_participantsUpdates_screenSharingInactive_otherUserWithoutHasVideoOrTrack_contentUpdates() async throws {
        let participant = CallParticipant.dummy()
        try await assertContentUpdate {
            $0.state.participants = [participant]
        } validation: {
            switch $0 {
            case let .participant(_, contentParticipant, _):
                return participant == contentParticipant
            default:
                return false
            }
        }
    }

    func test_participantsUpdates_screenSharingInactive_localParticipant_contentUpdates() async throws {
        var participant: CallParticipant!
        try await assertContentUpdate {
            participant = CallParticipant.dummy(
                trackSize: .init(width: 1, height: 1),
                sessionId: $0.state.sessionId
            )
            $0.state.localParticipant = participant
            $0.state.participants = [participant]
        } validation: {
            switch $0 {
            case let .participant(_, contentParticipant, _):
                return participant == contentParticipant
            default:
                return false
            }
        }
    }

    func test_participantsUpdates_noParticipants_contentUpdates() async throws {
        try await assertContentUpdate {
            $0.state.participants = []
        } validation: {
            $0 == .inactive
        }
    }

    // MARK: - PreferredContentSize Updates

    // MARK: isActive:false

    func test_preferredContentSizeUpdates_pipIsNotActive_screenSharingInactive_dominantSpeakerWithTrack_preferredContentSizeUpdates(
    ) async throws {
        let expected = CGSize(width: 1, height: 1)
        let videoTrack = RTCMediaStreamTrack.dummy(
            kind: .video,
            peerConnectionFactory: mockPeerConnectionFactory
        ) as? RTCVideoTrack
        let participant = CallParticipant.dummy(
            hasVideo: true,
            track: videoTrack,
            trackSize: expected,
            isDominantSpeaker: true
        )
        try await assertPreferredContentSizeUpdate(isActive: false, expected: expected) {
            $0.state.participants = [participant]
        }
    }

    func test_preferredContentSizeUpdates_pipIsNotActive_screenSharingInactive_otherUserWithVideoAndTrack_preferredContentSizeUpdates(
    ) async throws {
        let expected = CGSize(width: 1, height: 1)
        let videoTrack = RTCMediaStreamTrack.dummy(
            kind: .video,
            peerConnectionFactory: mockPeerConnectionFactory
        ) as? RTCVideoTrack
        let participant = CallParticipant.dummy(
            hasVideo: true,
            track: videoTrack,
            trackSize: expected
        )
        try await assertPreferredContentSizeUpdate(isActive: false, expected: expected) {
            $0.state.participants = [participant]
        }
    }

    func test_preferredContentSizeUpdates_pipIsNotActive_screenSharingInactive_localParticipant_preferredContentSizeUpdates(
    ) async throws {
        let expected = CGSize(width: 1, height: 1)

        try await assertPreferredContentSizeUpdate(isActive: false, expected: expected) {
            let participant = CallParticipant.dummy(
                hasVideo: true,
                trackSize: expected,
                sessionId: $0.state.sessionId
            )
            $0.state.localParticipant = participant
            $0.state.participants = [participant]
        }
    }

    // MARK: isActive:true

    func test_preferredContentSizeUpdates_pipIsActive_screenSharingInactive_dominantSpeakerWithTrack_preferredContentSizeUpdates(
    ) async throws {
        let expected = CGSize(width: 1, height: 1)
        let videoTrack = RTCMediaStreamTrack.dummy(
            kind: .video,
            peerConnectionFactory: mockPeerConnectionFactory
        ) as? RTCVideoTrack
        let participant = CallParticipant.dummy(
            hasVideo: true,
            track: videoTrack,
            trackSize: expected,
            isDominantSpeaker: true
        )
        try await assertPreferredContentSizeUpdate(isActive: true, expected: expected) {
            $0.state.participants = [participant]
        }
    }

    func test_preferredContentSizeUpdates_pipIsActive_screenSharingInactive_otherUserWithVideoAndTrack_preferredContentSizeUpdates(
    ) async throws {
        let expected = CGSize(width: 1, height: 1)
        let videoTrack = RTCMediaStreamTrack.dummy(
            kind: .video,
            peerConnectionFactory: mockPeerConnectionFactory
        ) as? RTCVideoTrack
        let participant = CallParticipant.dummy(
            hasVideo: true,
            track: videoTrack,
            trackSize: expected
        )
        try await assertPreferredContentSizeUpdate(isActive: true, expected: expected) {
            $0.state.participants = [participant]
        }
    }

    func test_preferredContentSizeUpdates_pipIsActive_screenSharingInactive_localParticipant_preferredContentSizeUpdates(
    ) async throws {
        let expected = CGSize(width: 1, height: 1)
        try await assertPreferredContentSizeUpdate(isActive: true, expected: expected) {
            let participant = CallParticipant.dummy(
                hasVideo: true,
                trackSize: expected,
                sessionId: $0.state.sessionId
            )
            $0.state.localParticipant = participant
            $0.state.participants = [participant]
        }
    }

    // MARK: - Private Helpers

    private func assertContentUpdate(
        _ operation: @MainActor @escaping @Sendable (MockCall) -> Void,
        validation: @escaping (PictureInPictureContent) -> Bool,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        // Given
        let call: MockCall = MockCall(.dummy(callController: .dummy(videoConfig: Self.videoConfig)))
        store.dispatch(.setCall(call))
        await fulfilmentInMainActor { self.store.state.call?.cId == call.cId }

        _ = await Task { @MainActor in
            operation(call)
        }.result

        _ = try await store
            .publisher(for: \.content)
            .filter { validation($0) }
            .eraseToAnyPublisher()
            .nextValue(timeout: defaultTimeout)
    }

    private func assertPreferredContentSizeUpdate(
        isActive: Bool,
        expected: CGSize,
        _ operation: @MainActor @escaping @Sendable (MockCall) -> Void,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) async throws {
        // Given
        let call: MockCall = MockCall(.dummy(callController: .dummy(videoConfig: Self.videoConfig)))
        await wait(for: 1.0)
        store.dispatch(.setCall(call))
        await fulfilmentInMainActor { self.store.state.call?.cId == call.cId }

        _ = await Task { @MainActor in
            operation(call)
        }.result

        await fulfilmentInMainActor { self.store.state.preferredContentSize == expected }
    }
}
