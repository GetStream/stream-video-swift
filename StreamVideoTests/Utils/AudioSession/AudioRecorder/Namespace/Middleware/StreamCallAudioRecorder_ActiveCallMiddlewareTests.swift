//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_ActiveCallMiddlewareTests: StreamVideoTestCase, @unchecked Sendable {

    private lazy var subject: StreamCallAudioRecorder
        .Namespace
        .ActiveCallMiddleware! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - activeCall updates

    func test_activeCall_nonNilWithAudioOn_dispatchesSetShouldRecordTrue() async throws {
        let validation = expectation(description: "Dispatcher was called")
        subject.dispatcher = .init { action, _, _, _, _ in
            switch action {
            case let .setShouldRecord(value) where value == true:
                validation.fulfill()
            default:
                break
            }
        }

        let call = await MockCall(.dummy())
        try await call.microphone.enable()
        streamVideo.state.activeCall = call

        await safeFulfillment(of: [validation])
    }

    func test_activeCall_nonNilWithAudioOn_changesToAudioOnFalse_dispatchesSetShouldRecordFalse() async throws {
        let validation = expectation(description: "Dispatcher was called")
        subject.dispatcher = .init { action, _, _, _, _ in
            switch action {
            case let .setShouldRecord(value) where value == false:
                validation.fulfill()
            default:
                break
            }
        }

        let call = await MockCall(.dummy())
        try await call.microphone.enable()
        streamVideo.state.activeCall = call

        await wait(for: 0.1)
        try await call.microphone.disable()

        await safeFulfillment(of: [validation])
    }

    func test_activeCall_nil_noActionIsBeingDispatch() async throws {
        let validation = expectation(description: "Dispatcher was called")
        validation.isInverted = true
        subject.dispatcher = .init { _, _, _, _, _ in }
        
        let call = await MockCall(.dummy())
        try await call.microphone.enable()

        await safeFulfillment(of: [validation], timeout: 1)
    }
}
