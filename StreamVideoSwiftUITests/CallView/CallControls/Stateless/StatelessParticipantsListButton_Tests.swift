//
//  StatelessParticipantsListButton_Tests.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 1/5/24.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

final class StatelessParticipantsListButton_Tests: StreamVideoUITestCase {

    // MARK: - Appearance

    @MainActor
    func test_appearance_noParticipantsNotActive_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                0,
                isActive: false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_noParticipantsIsActive_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                0,
                isActive: true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_oneParticipantNotActive_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                1,
                isActive: false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_oneParticipantIsActive_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                1,
                isActive: true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_twoParticipantsNotActive_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                2,
                isActive: false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_twoParticipantsIsActive_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                2,
                isActive: true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    // MARK: Private helpers

    @MainActor
    private func makeSubject(
        _ participantsCount: Int = 0,
        isActive: Bool = false,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> StatelessParticipantsListButton {
        let call = try XCTUnwrap(
            streamVideoUI?.streamVideo.call(
                callType: .default,
                callId: "test"
            ),
            file: file,
            line: line
        )
        call.state.participantsMap = (0..<participantsCount).reduce(into: [String: CallParticipant](), { partialResult, _ in
            let userId = UUID().uuidString
            partialResult[userId] = .dummy(id: userId)
        })

        return .init(call: call, isActive: .constant(isActive))
    }
}

