//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_CategoryMiddlewareTests: XCTestCase, @unchecked Sendable {

    @Injected(\.audioStore) private var audioStore

    private lazy var subject: StreamCallAudioRecorder
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

        audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    .playAndRecord,
                    mode: .voiceChat,
                    categoryOptions: []
                )
            )
        )

        await safeFulfillment(of: [validation], timeout: 1)
    }

    func test_audioStoreCategory_record_noActionDispatch() async {
        let validation = expectation(description: "Dispatcher was called")
        validation.isInverted = true
        subject.dispatcher = .init { _, _, _, _ in }

        audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    .record,
                    mode: .voiceChat,
                    categoryOptions: []
                )
            )
        )

        await safeFulfillment(of: [validation], timeout: 1)
    }

    func test_audioStoreCategory_noRecordOrPlaybackCategory_setIsRecordingDispatchWithFalse() async throws {
        try await audioStore.dispatch(.avAudioSession(.setCategory(.playAndRecord))).result()
        let validation = expectation(description: "Dispatcher was called")
        subject.dispatcher = .init { actions, _, _, _ in
            switch actions[0].wrappedValue {
            case let .setIsRecording(value) where value == false:
                validation.fulfill()
            default:
                break
            }
        }

        audioStore.dispatch(
            .avAudioSession(
                .setCategoryAndModeAndCategoryOptions(
                    .playback,
                    mode: .default,
                    categoryOptions: []
                )
            )
        )

        await safeFulfillment(of: [validation])
    }
}
