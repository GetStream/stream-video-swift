//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class CallState_Tests: XCTestCase, @unchecked Sendable {

    /// Test the `didUpdate(_:)` function by combining existing and newly added participants.
    func test_didUpdate_combinesExistingAndNewParticipants() {
        assertParticipantsUpdate(
            initial: [
                CallParticipant.dummy(id: "1")
            ],
            update: { $0 + [CallParticipant.dummy(id: "2")] },
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test the `didUpdate(_:)` function with sorting participants using defaultComparators.
    func test_didUpdate_sortsParticipantsUsingDefaultComparators() {
        assertParticipantsUpdate(
            initial: [
                CallParticipant.dummy(id: "1", name: "Zane")
            ],
            update: { $0 + [CallParticipant.dummy(id: "2", name: "Aaron")] },
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test the `didUpdate(_:)` function by ensuring that duplicated participants are not added.
    func test_didUpdate_avoidsDuplicateParticipants() {
        assertParticipantsUpdate(
            initial: [
                CallParticipant.dummy(id: "1")
            ],
            update: { $0 },
            expectedTransformer: { [$0[0]] }
        )
    }

    /// Test the `didUpdate(_:)` function by sorting participants using the `isSpeaking` property.
    func test_didUpdate_sortsParticipantsBySpeaking() {
        assertParticipantsUpdate(
            initial: [
                .dummy(id: "1", isSpeaking: false),
                .dummy(id: "3", isSpeaking: false)
            ],
            update: { initial in
                initial + [
                    .dummy(id: "2", isSpeaking: true),
                    .dummy(id: "4", isSpeaking: true)
                ]
            },
            expectedTransformer: { updated in
                [updated[2], updated[3], updated[0], updated[1]]
            }
        )
    }

    /// Test the `didUpdate(_:)` function by sorting participants using the `hasVideo` property.
    func test_didUpdate_sortsParticipantsByVideo() {
        assertParticipantsUpdate(
            initial: [
                .dummy(id: "1", hasVideo: false),
                .dummy(id: "3", hasVideo: false)
            ],
            update: { initial in
                initial + [
                    .dummy(id: "2", hasVideo: true),
                    .dummy(id: "4", hasVideo: true)
                ]
            },
            expectedTransformer: { updated in
                [updated[2], updated[3], updated[0], updated[1]]
            }
        )
    }

    /// Test the `didUpdate(_:)` function by sorting participants using the `hasAudio` property.
    func test_didUpdate_sortsParticipantsByAudio() {
        assertParticipantsUpdate(
            initial: [
                .dummy(id: "1", hasAudio: false),
                .dummy(id: "3", hasAudio: false)
            ],
            update: { initial in
                initial + [
                    .dummy(id: "2", hasAudio: true),
                    .dummy(id: "4", hasAudio: true)
                ]
            },
            expectedTransformer: { updated in
                [updated[2], updated[3], updated[0], updated[1]]
            }
        )
    }

    /// Test the `didUpdate(_:)` function by sorting participants using the `userId` property.
    func test_didUpdate_sortsParticipantsByUserId() {
        assertParticipantsUpdate(
            initial: [
                .dummy(id: "1", userId: "B"),
                .dummy(id: "3", userId: "D")
            ],
            update: { initial in
                initial + [
                    .dummy(id: "2", userId: "A"),
                    .dummy(id: "4", userId: "C")
                ]
            },
            expectedTransformer: { updated in
                [updated[2], updated[0], updated[3], updated[1]]
            }
        )
    }

    /// Test the `didUpdate(_:)` function by sorting participants based on speaking and video properties.
    func test_didUpdate_sortsParticipantsBySpeakingAndVideo() {
        assertParticipantsUpdate(
            initial: [
                .dummy(id: "1", hasVideo: false, isSpeaking: true),
                .dummy(id: "3", hasVideo: true, isSpeaking: false)
            ],
            update: { initial in
                initial + [
                    .dummy(id: "2", hasVideo: true, isSpeaking: true),
                    .dummy(id: "4", hasVideo: false, isSpeaking: false)
                ]
            },
            expectedTransformer: { updated in
                [updated[2], updated[0], updated[1], updated[3]]
            }
        )
    }

    /// Test the `didUpdate(_:)` function by sorting participants based on joined time and audio properties.
    func test_didUpdate_sortsParticipantsByUserIdAndAudio() {
        assertParticipantsUpdate(
            initial: [
                .dummy(id: "1", hasAudio: true),
                .dummy(id: "3", hasAudio: false)
            ],
            update: { initial in
                initial + [
                    .dummy(id: "2", hasAudio: true),
                    .dummy(id: "4", hasAudio: false)
                ]
            },
            expectedTransformer: { updated in
                [updated[0], updated[2], updated[1], updated[3]]
            }
        )
    }

    /// Test the `didUpdate(_:)` function by sorting participants based on userId and speaking properties.
    func test_didUpdate_sortsParticipantsByUserIdAndSpeaking() {
        assertParticipantsUpdate(
            initial: [
                .dummy(id: "1", userId: "A", showTrack: false, isSpeaking: false),
                .dummy(id: "3", userId: "D", showTrack: true, isSpeaking: true)
            ],
            update: { initial in
                initial + [
                    .dummy(id: "2", userId: "B", showTrack: true, isSpeaking: true),
                    .dummy(id: "4", userId: "C", showTrack: false, isSpeaking: false)
                ]
            },
            expectedTransformer: { updated in
                [updated[1], updated[2], updated[0], updated[3]]
            }
        )
    }

    /// Test the execution time of `didUpdate` with many merge/add/remove operations.
    func test_didUpdate_performanceWithManyParticipants_timeExecutionIsLessThanMaxDuration() {
        let subject = CallState(.dummy())
        let cycleCount = 250

        assertDuration(maxDuration: 5) {
            /// Add 2500 users
            (0..<10).forEach {
                add(count: cycleCount, namePrefix: $0, in: subject)
                XCTAssertEqual(subject.participants.count, cycleCount * ($0 + 1))
            }
            XCTAssertEqual(subject.participants.count, 2500)

            /// Remove half of them
            dropFirst(count: 1250, from: subject)
            XCTAssertEqual(subject.participants.count, 1250)

            /// Add 1250 users
            (0..<5).forEach { add(count: cycleCount, namePrefix: $0, in: subject) }
            XCTAssertEqual(subject.participants.count, 2500)
        }
    }

    func test_update_fromJoinCallResponse_doesNotOverwriteCallSettings() {
        let mockStreamVideo = MockStreamVideo()
        let subject = CallState(mockStreamVideo.callSession)
        let initialCallSettings = CallSettings(
            audioOn: true,
            videoOn: false,
            speakerOn: false,
            audioOutputOn: false,
            cameraPosition: .back
        )
        subject.update(callSettings: initialCallSettings)

        let remoteCallResponse = CallResponse.dummy(
            settings: .dummy(
                audio: .dummy(micDefaultOn: false),
                video: .dummy(cameraFacing: .front)
            )
        )
        subject.update(from: JoinCallResponse.dummy(call: remoteCallResponse))

        XCTAssertEqual(subject.callSettings, initialCallSettings)
    }

    func test_update_fromCallResponse_withoutStartedSession_keepsDurationReset() {
        let subject = CallState(.dummy())

        subject.update(
            from: CallResponse.dummy(
                session: .dummy()
            )
        )

        XCTAssertNil(subject.startedAt)
        XCTAssertEqual(subject.duration, 0)
    }

    func test_update_fromCallResponse_withStartedAt_usesActualCallStart() {
        let subject = CallState(.dummy())
        let startedAt = Date(timeIntervalSinceNow: -95)

        subject.update(
            from: CallResponse.dummy(
                session: .dummy(
                    liveStartedAt: Date(timeIntervalSinceNow: -120),
                    startedAt: startedAt
                )
            )
        )

        XCTAssertEqual(subject.startedAt, startedAt)
        XCTAssertEqual(
            subject.duration,
            Date().timeIntervalSince(startedAt),
            accuracy: 1
        )
    }

    func test_update_fromCallResponse_withOnlyLiveStartedAt_usesLiveStartedAt() {
        let subject = CallState(.dummy())
        let liveStartedAt = Date(timeIntervalSinceNow: -42)

        subject.update(
            from: CallResponse.dummy(
                session: .dummy(
                    liveStartedAt: liveStartedAt
                )
            )
        )

        XCTAssertEqual(subject.startedAt, liveStartedAt)
        XCTAssertEqual(
            subject.duration,
            Date().timeIntervalSince(liveStartedAt),
            accuracy: 1
        )
    }

    func test_update_fromCallResponse_withEndedSession_resetsDuration() {
        let subject = CallState(.dummy())
        let startedAt = Date(timeIntervalSinceNow: -30)

        subject.update(
            from: CallResponse.dummy(
                session: .dummy(
                    startedAt: startedAt
                )
            )
        )

        subject.update(
            from: CallResponse.dummy(
                session: .dummy(
                    endedAt: Date(),
                    startedAt: startedAt
                )
            )
        )

        XCTAssertNil(subject.startedAt)
        XCTAssertEqual(subject.duration, 0)
    }

    // MARK: - Private helpers

    private func assertParticipantsUpdate(
        initial: [CallParticipant],
        update: @escaping (_ initial: [CallParticipant]) -> [CallParticipant],
        expectedTransformer: @escaping ([CallParticipant]) -> [CallParticipant],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let subject = CallState(.dummy())
        subject.participantsMap = initial.reduce([String: CallParticipant]()) {
            var mutated = $0
            mutated[$1.id] = $1
            return mutated
        }

        let updated = update(initial)
        let expected = expectedTransformer(updated)
        subject.participantsMap = updated.reduce([String: CallParticipant]()) {
            var mutated = $0
            mutated[$1.id] = $1
            return mutated
        }
        let actualIndexes = subject.participants.map { updated.firstIndex(of: $0) ?? -1 }

        XCTAssertTrue(
            subject.participants == expected,
            "Sorting order error. Expected order [\(actualIndexes.map(\.description).joined(separator: ","))]",
            file: file,
            line: line
        )
    }

    private func makeCallParticipants(count: Int, nameSuffix: Int = 0) -> [CallParticipant] {
        (0..<count).map { _ in
            CallParticipant.dummy(name: "CallParticipant_\(nameSuffix + count)")
        }
    }

    private func add(count: Int, namePrefix: Int = 0, in subject: CallState) {
        let existingParticipants = subject.participants
        let newParticipants = makeCallParticipants(count: count, nameSuffix: namePrefix)

        subject.participantsMap = (existingParticipants + newParticipants)
            .reduce(into: [String: CallParticipant]()) { $0[$1.id] = $1 }
    }

    private func dropFirst(count: Int, from subject: CallState) {
        subject.participantsMap = subject
            .participants
            .dropFirst(count)
            .reduce(into: [String: CallParticipant]()) { $0[$1.id] = $1 }
    }

    private func assertDuration(
        maxDuration: TimeInterval,
        block: () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let startDate = Date()
        block()
        let duration = Date().timeIntervalSince(startDate)
        XCTAssertTrue(
            duration <= maxDuration,
            "Execution time was \(duration) with maximumDuration: \(maxDuration)",
            file: file,
            line: line
        )
    }
}
