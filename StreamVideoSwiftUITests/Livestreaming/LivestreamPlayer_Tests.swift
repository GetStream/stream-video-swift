//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

final class LivestreamPlayer_Tests: StreamVideoTestCase, @unchecked Sendable {
    
    private let callId = "test"
    private let callType = "livestream"
    private var mockStreamVideo: MockStreamVideo! = .init()

    override func tearDown() async throws {
        mockStreamVideo = nil
        try await super.tearDown()
    }

    @MainActor
    func test_livestreamPlayer_disappears_reportsAppInitiator() async {
        let call = MockCall()
        call.stub(for: .join, with: JoinCallResponse.dummy())
        let subject = UIHostingController(rootView: LivestreamPlayer(call: call))
        let window = UIWindow(frame: UIScreen.main.bounds)
        let container = UIViewController()
        container.addChild(subject)
        // Match snapshot traits before the spinner is first rendered.
        container.setOverrideTraitCollection(
            SnapshotVariant.defaultLight.traits,
            forChild: subject
        )
        subject.view.frame = window.bounds
        container.view.addSubview(subject.view)
        subject.didMove(toParent: container)
        window.rootViewController = container
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        await fulfillment { call.timesCalled(.join) == 1 }

        window.rootViewController = nil

        await fulfillment { call.timesCalled(.leave) == 1 }
        XCTAssertEqual(call.leaveInitiators, [.app])
    }

    @MainActor
    func test_livestreamPlayer_leave_reportsUserInitiator() {
        let call = MockCall()
        let subject = LivestreamPlayer(call: call)

        subject.leaveLivestream()

        XCTAssertEqual(call.leaveInitiators, [.user])
    }

    @MainActor
    func test_callEndedThenBackstageClears_joinsAFreshCall() async {
        let left = MockCall()
        left.state.backstage = true
        left.stub(for: .join, with: JoinCallResponse.dummy())
        let fresh = MockCall()
        fresh.stub(for: .join, with: JoinCallResponse.dummy())
        let video = MockStreamVideo()
        video.stub(for: .call, with: fresh)
        let previous = StreamVideoProviderKey.currentValue
        StreamVideoProviderKey.currentValue = video
        defer { StreamVideoProviderKey.currentValue = previous }
        let window = show(
            LivestreamPlayer(call: left, livestreamState: .backstage)
        )
        defer { window.isHidden = true }
        await fulfillment { left.timesCalled(.join) == 1 }

        NotificationCenter.default.post(
            name: Notification.Name(CallNotification.callEnded),
            object: left
        )
        left.state.backstage = false

        await fulfillment { fresh.timesCalled(.join) == 1 }
        XCTAssertEqual(left.timesCalled(.join), 1)
        guard
            case let .join(_, _, _, _, settings, _) = fresh
            .stubbedFunctionInput[.join]?
            .last
        else {
            XCTFail("Fresh call did not record a join")
            return
        }
        XCTAssertEqual(settings?.audioOn, false)
        XCTAssertEqual(settings?.videoOn, false)
    }

    @MainActor
    func test_joinPolicyNone_callEnded_doesNotJoinAFreshCall() async {
        let left = MockCall()
        left.state.backstage = true
        let fresh = MockCall()
        fresh.stub(for: .join, with: JoinCallResponse.dummy())
        let video = MockStreamVideo()
        video.stub(for: .call, with: fresh)
        let previous = StreamVideoProviderKey.currentValue
        StreamVideoProviderKey.currentValue = video
        defer { StreamVideoProviderKey.currentValue = previous }
        let window = show(
            LivestreamPlayer(
                call: left,
                livestreamState: .backstage,
                joinPolicy: .none
            )
        )
        defer { window.isHidden = true }

        NotificationCenter.default.post(
            name: Notification.Name(CallNotification.callEnded),
            object: left
        )
        left.state.backstage = false

        XCTAssertEqual(fresh.timesCalled(.join), 0)
        XCTAssertEqual(left.timesCalled(.join), 0)
    }

    @MainActor
    private func show<V: View>(_ view: V) -> UIWindow {
        let subject = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        let container = UIViewController()
        container.addChild(subject)
        subject.view.frame = window.bounds
        container.view.addSubview(subject.view)
        subject.didMove(toParent: container)
        window.rootViewController = container
        window.makeKeyAndVisible()
        return window
    }

    @MainActor
    func test_livestreamPlayer_snapshot() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = false
        let player = LivestreamPlayer(call: call, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_snapshotHideParticipantCount() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = false
        let player = LivestreamPlayer(call: call, showParticipantCount: false, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_backstageStartsAt() async throws {
        // Given
        let countdown: TimeInterval = 120
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = true
        call.state.startsAt = Date(timeIntervalSinceNow: countdown)
        let player = LivestreamPlayer(call: call, countdown: countdown, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_backstageStartsAtWithParticipants() async throws {
        // Given
        let countdown: TimeInterval = 120
        let call = streamVideo.call(callType: callType, callId: callId)
        call.state.backstage = true
        call.state.startsAt = Date(timeIntervalSinceNow: countdown)
        call.state.session = CallSessionResponse.dummy(participants: [.dummy(), .dummy()])
        let player = LivestreamPlayer(call: call, countdown: countdown, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_errorState() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        let player = LivestreamPlayer(call: call, livestreamState: .error, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_joiningState() async throws {
        // Given
        let call = streamVideo.call(callType: callType, callId: callId)
        let player = LivestreamPlayer(call: call, livestreamState: .joining, joinPolicy: .none)
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)

        // The joining view is a spinning indicator.
        // The check allows that motion.
        let previousPrecision = precision
        precision = 0.9
        defer { precision = previousPrecision }

        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
    
    @MainActor
    func test_livestreamPlayer_endedState() async throws {
        // Given
        let call = MockCall()
        let recording = CallRecording(
            endTime: .now,
            filename: "test",
            recordingType: "composite",
            sessionId: "test",
            startTime: .distantFuture,
            url: "https://test.com"
        )
        call.state.endedAt = .now
        
        // When
        let player = LivestreamPlayer(call: call, joinPolicy: .none, recordings: [recording])
            .frame(width: defaultScreenSize.width, height: defaultScreenSize.height)
        
        // Then
        AssertSnapshot(player, variants: [.defaultLight, .defaultDark])
    }
}
