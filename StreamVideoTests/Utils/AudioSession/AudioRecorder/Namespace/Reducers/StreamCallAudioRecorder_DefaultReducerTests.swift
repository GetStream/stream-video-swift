//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class StreamCallAudioRecorder_DefaultReducerTests: XCTestCase, @unchecked Sendable {

    private lazy var subject: StreamCallAudioRecorder.Namespace.DefaultReducer! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - reduce

    // MARK: isRecording

    func test_reducer_setIsRecording_true_returnsExpectedState() async throws {
        try await assertState(
            action: .setIsRecording(true),
            validation: { $0.isRecording == true }
        )
    }

    func test_reducer_setIsRecording_false_returnsExpectedState() async throws {
        try await assertState(
            action: .setIsRecording(false),
            validation: { $0.isRecording == false }
        )
    }

    // MARK: isInterrupted

    func test_reducer_setIsInterrupted_true_returnsExpectedState() async throws {
        try await assertState(
            action: .setIsInterrupted(true),
            validation: { $0.isInterrupted == true }
        )
    }

    func test_reducer_setIsInterrupted_false_returnsExpectedState() async throws {
        try await assertState(
            action: .setIsInterrupted(false),
            validation: { $0.isInterrupted == false }
        )
    }

    // MARK: shouldRecord

    func test_reducer_setShouldRecord_true_returnsExpectedState() async throws {
        try await assertState(
            action: .setShouldRecord(true),
            validation: { $0.shouldRecord == true }
        )
    }

    func test_reducer_setShouldRecord_false_returnsExpectedState() async throws {
        try await assertState(
            action: .setShouldRecord(false),
            validation: { $0.shouldRecord == false }
        )
    }

    // MARK: meter

    func test_reducer_setMeter_true_returnsExpectedState() async throws {
        try await assertState(
            action: .setMeter(10.1),
            validation: { $0.meter == 10.1 }
        )
    }

    // MARK: - Private Helpers

    private func assertState(
        action: StreamCallAudioRecorder.Namespace.Action,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        validation: (StreamCallAudioRecorder.Namespace.State) -> Bool
    ) async throws {
        let actual = try await subject.reduce(
            state: .initial,
            action: action,
            file: file,
            function: function,
            line: line
        )

        XCTAssertTrue(validation(actual), file: file, line: line)
    }
}
