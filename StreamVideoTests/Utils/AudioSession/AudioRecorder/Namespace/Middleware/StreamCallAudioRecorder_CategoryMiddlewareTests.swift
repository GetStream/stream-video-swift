//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_CategoryMiddlewareTests: XCTestCase, @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    private var subject: StreamCallAudioRecorder
        .Namespace
        .CategoryMiddleware! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_audioStoreCategory_playAndRecord_noActionDispatch() async {
        let validation = expectation(description: "Dispatcher was called")
        validation.isInverted = true
        subject.dispatcher = .init { _, _, _, _ in }

        audioStore.dispatch(.audioSession(.setCategory(.playAndRecord, mode: .videoChat, options: [])))

        await safeFulfillment(of: [validation], timeout: 1)
    }

    func test_audioStoreCategory_record_noActionDispatch() async {
        let validation = expectation(description: "Dispatcher was called")
        validation.isInverted = true
        subject.dispatcher = .init { _, _, _, _ in }

        audioStore.dispatch(.audioSession(.setCategory(.record, mode: .videoChat, options: [])))

        await safeFulfillment(of: [validation], timeout: 1)
    }

    func test_audioStoreCategory_noRecordOrPlaybackCategory_setIsRecordingDispatchWithFalse() async {
        let validation = expectation(description: "Dispatcher was called")
        subject.dispatcher = .init { actions, _, _, _ in
            switch actions[0].wrappedValue {
            case let .setIsRecording(value) where value == false:
                validation.fulfill()
            default:
                break
            }
        }

        audioStore.dispatch(.audioSession(.setCategory(.playback, mode: .videoChat, options: [])))

        await safeFulfillment(of: [validation])
    }
}
