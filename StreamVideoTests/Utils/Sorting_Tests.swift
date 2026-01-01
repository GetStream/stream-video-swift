//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class Sorting_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - pinned

    /// Test with only pinned participants.
    func test_pinned_allPinned() {
        assertSort(
            [
                .dummy(pin: PinInfo(isLocal: true, pinnedAt: Date(timeIntervalSince1970: 100))),
                .dummy(pin: PinInfo(isLocal: true, pinnedAt: Date(timeIntervalSince1970: 200)))
            ],
            comparator: pinned,
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    /// Test with only unpinned participants.
    func test_pinned_noPinned() {
        assertSort(
            [
                .dummy(),
                .dummy()
            ],
            comparator: pinned,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with a mix of pinned and unpinned participants.
    func test_pinned_mixedPinned() {
        assertSort(
            [
                .dummy(),
                .dummy(pin: PinInfo(isLocal: true, pinnedAt: Date(timeIntervalSince1970: 100)))
            ],
            comparator: pinned,
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    /// Test with pinned participants having different pinnedAt dates.
    func test_pinned_differentPinnedDates() {
        assertSort(
            [
                .dummy(pin: PinInfo(isLocal: true, pinnedAt: Date(timeIntervalSince1970: 50))),
                .dummy(pin: PinInfo(isLocal: true, pinnedAt: Date(timeIntervalSince1970: 100)))
            ],
            comparator: pinned,
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    /// Test with pinned participants having different pinnedAt dates.
    func test_pinned_localAndRemote() {
        assertSort(
            [
                .dummy(pin: PinInfo(isLocal: true, pinnedAt: Date(timeIntervalSince1970: 0))),
                .dummy(pin: PinInfo(isLocal: false, pinnedAt: Date(timeIntervalSince1970: 0)))
            ],
            comparator: pinned,
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    // MARK: - screenSharing

    /// Test with all participants screen sharing.
    func test_screenSharing_allSharing() {
        assertSort(
            [
                .dummy(userId: "A", isScreenSharing: true),
                .dummy(userId: "B", isScreenSharing: true)
            ],
            comparator: combineComparators(speakerLayoutSortPreset),
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with no participants screen sharing.
    func test_screenSharing_noSharing() {
        assertSort(
            [
                .dummy(userId: "A", isScreenSharing: false),
                .dummy(userId: "B", isScreenSharing: false)
            ],
            comparator: combineComparators(speakerLayoutSortPreset),
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with a mix of participants screen sharing and not.
    func test_screenSharing_mixedSharing() {
        assertSort(
            [
                .dummy(isScreenSharing: false),
                .dummy(isScreenSharing: true)
            ],
            comparator: combineComparators(speakerLayoutSortPreset),
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    // MARK: - isDominantSpeaker

    /// Test with all participants as dominant speakers.
    func test_dominantSpeaker_allDominant() {
        assertSort(
            [
                .dummy(isDominantSpeaker: true),
                .dummy(isDominantSpeaker: true)
            ],
            comparator: dominantSpeaker,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with no participants as dominant speakers.
    func test_dominantSpeaker_noDominant() {
        assertSort(
            [
                .dummy(isDominantSpeaker: false),
                .dummy(isDominantSpeaker: false)
            ],
            comparator: dominantSpeaker,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with a mix of dominant speakers and non-dominant speakers.
    func test_dominantSpeaker_mixedDominant() {
        assertSort(
            [
                .dummy(isDominantSpeaker: false),
                .dummy(isDominantSpeaker: true)
            ],
            comparator: dominantSpeaker,
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    // MARK: - isSpeaking

    /// Test with all participants speaking.
    func test_isSpeaking_allSpeaking() {
        assertSort(
            [
                .dummy(isSpeaking: true),
                .dummy(isSpeaking: true)
            ],
            comparator: speaking,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with no participants speaking.
    func test_isSpeaking_noSpeaking() {
        assertSort(
            [
                .dummy(isSpeaking: false),
                .dummy(isSpeaking: false)
            ],
            comparator: speaking,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with a mix of participants who are and aren't speaking.
    func test_isSpeaking_mixedSpeaking() {
        assertSort(
            [
                .dummy(isSpeaking: false),
                .dummy(isSpeaking: true)
            ],
            comparator: speaking,
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    // MARK: - publishingVideo

    /// Test with all participants publishing video.
    func test_publishingVideo_allPublishing() {
        assertSort(
            [
                .dummy(hasVideo: true),
                .dummy(hasVideo: true)
            ],
            comparator: publishingVideo,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with no participants publishing video.
    func test_publishingVideo_noPublishing() {
        assertSort(
            [
                .dummy(hasVideo: false),
                .dummy(hasVideo: false)
            ],
            comparator: publishingVideo,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with a mix of participants who are and aren't publishing video.
    func test_publishingVideo_mixedPublishing() {
        assertSort(
            [
                .dummy(hasVideo: false),
                .dummy(hasVideo: true)
            ],
            comparator: publishingVideo,
            expectedTransformer: { [$0[1], $0[0]] } // Expecting the one publishing video to be first.
        )
    }

    // MARK: - publishingAudio

    /// Test with all participants publishing audio.
    func test_publishingAudio_allPublishing() {
        assertSort(
            [
                .dummy(hasAudio: true),
                .dummy(hasAudio: true)
            ],
            comparator: publishingAudio,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with no participants publishing audio.
    func test_publishingAudio_noPublishing() {
        assertSort(
            [
                .dummy(hasAudio: false),
                .dummy(hasAudio: false)
            ],
            comparator: publishingAudio,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with a mix of participants who are and aren't publishing audio.
    func test_publishingAudio_mixedPublishing() {
        assertSort(
            [
                .dummy(hasAudio: false),
                .dummy(hasAudio: true)
            ],
            comparator: publishingAudio,
            expectedTransformer: { [$0[1], $0[0]] } // Expecting the one publishing audio to be first.
        )
    }

    // MARK: - name

    /// Test with participants having names in alphabetical order.
    func test_name_alreadySorted() {
        assertSort(
            [
                .dummy(name: "Adam"),
                .dummy(name: "Eve")
            ],
            comparator: nameComparator,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    /// Test with participants having names in non-alphabetical order.
    func test_name_unsorted() {
        assertSort(
            [
                .dummy(name: "Zane"),
                .dummy(name: "Aaron")
            ],
            comparator: nameComparator,
            expectedTransformer: { [$0[1], $0[0]] } // Expecting the names in alphabetical order.
        )
    }

    /// Test with participants having names with varied casing.
    func test_name_mixedCase() {
        assertSort(
            [
                .dummy(name: "aaron"),
                .dummy(name: "Aaron"),
                .dummy(name: "AARON")
            ],
            comparator: nameComparator,
            expectedTransformer: { [$0[0], $0[1], $0[2]] } // Expecting a case-insensitive alphabetical order.
        )
    }

    /// Test with participants having identical names.
    func test_name_identical() {
        assertSort(
            [
                .dummy(name: "Adam"),
                .dummy(name: "Adam")
            ],
            comparator: nameComparator,
            expectedTransformer: { [$0[0], $0[1]] } // Order doesn't matter when names are identical.
        )
    }

    // MARK: - roles

    /// Test the `roles` comparator with participants having priority roles.
    func test_roles_priorityRoles() {
        let rolesComparator = roles(["admin"])

        assertSort(
            [
                .dummy(roles: ["speaker"]),
                .dummy(roles: ["host"]),
                .dummy(roles: ["admin"])
            ],
            comparator: rolesComparator,
            expectedTransformer: { [$0[2], $0[0], $0[1]] }
        )
    }

    /// Test the `roles` comparator with one participant having a priority role and the other not.
    func test_roles_oneWithPriority() {
        let rolesComparator = roles()

        assertSort(
            [
                .dummy(roles: ["speaker"]),
                .dummy(roles: ["member"])
            ],
            comparator: rolesComparator,
            expectedTransformer: { [$0[0], $0[1]] } // "speaker" has priority over "member".
        )
    }

    /// Test the `roles` comparator with both participants having non-priority roles.
    func test_roles_noPriority() {
        let rolesComparator = roles()

        assertSort(
            [
                .dummy(roles: ["member"]),
                .dummy(roles: ["user"])
            ],
            comparator: rolesComparator,
            expectedTransformer: { [$0[0], $0[1]] } // The order remains unchanged as neither role has priority.
        )
    }

    /// Test the `roles` comparator with participants having multiple roles.
    func test_roles_multipleRoles() {
        let rolesComparator = roles()

        assertSort(
            [
                .dummy(roles: ["member", "admin"]),
                .dummy(roles: ["host", "user"])
            ],
            comparator: rolesComparator,
            expectedTransformer: { [$0[0], $0[1]] } // "admin" has the highest priority among all roles in the list.
        )
    }

    /// Test with participants having no roles.
    func test_roles_noRoles() {
        assertSort(
            [
                .dummy(roles: []),
                .dummy(roles: [])
            ],
            comparator: roles(["admin", "host", "speaker", "attendee"]),
            expectedTransformer: { [$0[0], $0[1]] } // Order doesn't matter when there are no roles.
        )
    }

    // MARK: - id

    /// Test with participants having IDs in alphabetical order.
    func test_id_alreadySorted() {
        assertSort(
            [
                .dummy(id: "A123"),
                .dummy(id: "B456"),
                .dummy(id: "C789")
            ],
            comparator: id,
            expectedTransformer: { [$0[0], $0[1], $0[2]] }
        )
    }

    /// Test with participants having IDs in a random order.
    func test_id_unsorted() {
        assertSort(
            [
                .dummy(id: "B456"),
                .dummy(id: "A123"),
                .dummy(id: "C789")
            ],
            comparator: id,
            expectedTransformer: { [$0[1], $0[0], $0[2]] }
        )
    }

    /// Test with participants having identical IDs.
    func test_id_identical() {
        assertSort(
            [
                .dummy(id: "A123"),
                .dummy(id: "A123")
            ],
            comparator: id,
            expectedTransformer: { [$0[0], $0[1]] } // Order doesn't matter when IDs are identical.
        )
    }

    // MARK: - userId

    /// Test with participants having user IDs in alphabetical order.
    func test_userId_alreadySorted() {
        assertSort(
            [
                .dummy(userId: "A123"),
                .dummy(userId: "B456"),
                .dummy(userId: "C789")
            ],
            comparator: userId,
            expectedTransformer: { [$0[0], $0[1], $0[2]] }
        )
    }

    /// Test with participants having user IDs in a random order.
    func test_userId_unsorted() {
        assertSort(
            [
                .dummy(userId: "B456"),
                .dummy(userId: "A123"),
                .dummy(userId: "C789")
            ],
            comparator: userId,
            expectedTransformer: { [$0[1], $0[0], $0[2]] }
        )
    }

    /// Test with participants having identical user IDs.
    func test_userId_identical() {
        assertSort(
            [
                .dummy(userId: "A123"),
                .dummy(userId: "A123")
            ],
            comparator: userId,
            expectedTransformer: { [$0[0], $0[1]] } // Order doesn't matter when user IDs are identical.
        )
    }

    // MARK: - joinedAt

    /// Test with participants who joined the call in chronological order.
    func test_joinedAt_alreadySorted() {
        assertSort(
            [
                .dummy(joinedAt: Date(timeIntervalSince1970: 1000)),
                .dummy(joinedAt: Date(timeIntervalSince1970: 2000)),
                .dummy(joinedAt: Date(timeIntervalSince1970: 3000))
            ],
            comparator: joinedAt,
            expectedTransformer: { [$0[0], $0[1], $0[2]] }
        )
    }

    /// Test with participants who joined the call in a random order.
    func test_joinedAt_unsorted() {
        assertSort(
            [
                .dummy(joinedAt: Date(timeIntervalSince1970: 2000)),
                .dummy(joinedAt: Date(timeIntervalSince1970: 1000)),
                .dummy(joinedAt: Date(timeIntervalSince1970: 3000))
            ],
            comparator: joinedAt,
            expectedTransformer: { [$0[1], $0[0], $0[2]] }
        )
    }

    /// Test with participants who joined the call at the same time.
    func test_joinedAt_identical() {
        assertSort(
            [
                .dummy(joinedAt: Date(timeIntervalSince1970: 1000)),
                .dummy(joinedAt: Date(timeIntervalSince1970: 1000))
            ],
            comparator: joinedAt,
            expectedTransformer: { [$0[0], $0[1]] } // Order doesn't matter when join times are identical.
        )
    }

    // MARK: - combineComparators

    /// Test with multiple comparators where the `name` comparator determines the order.
    func test_combineComparators_nameDetermines() {
        assertSort(
            [
                .dummy(id: "1", userId: "A", name: "Zane"),
                .dummy(id: "2", userId: "B", name: "Aaron")
            ],
            comparator: combineComparators([nameComparator, id, userId]),
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    /// Test with multiple comparators where the `id` comparator determines the order because the names are the same.
    func test_combineComparators_idDetermines() {
        assertSort(
            [
                .dummy(id: "2", userId: "A", name: "Aaron"),
                .dummy(id: "1", userId: "B", name: "Aaron")
            ],
            comparator: combineComparators([nameComparator, id, userId]),
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    /// Test with multiple comparators where the `userId` comparator determines the order because the names and IDs are the same.
    func test_combineComparators_userIdDetermines() {
        assertSort(
            [
                .dummy(id: "1", userId: "B", name: "Aaron"),
                .dummy(id: "1", userId: "A", name: "Aaron")
            ],
            comparator: combineComparators([nameComparator, id, userId]),
            expectedTransformer: { [$0[1], $0[0]] }
        )
    }

    /// Test with multiple comparators, all returning .orderedSame because names, IDs, and userIds are identical.
    func test_combineComparators_allSame() {
        assertSort(
            [
                .dummy(id: "1", userId: "A", name: "Aaron"),
                .dummy(id: "1", userId: "A", name: "Aaron")
            ],
            comparator: combineComparators([nameComparator, id, userId]),
            expectedTransformer: { [$0[0], $0[1]] } // Order doesn't matter when all comparators return .orderedSame.
        )
    }

    // MARK: - conditional

    /// Test the `name` comparator conditionally based on `id`.
    func test_conditional_nameBasedOnId() {
        let condition = conditional { (a: CallParticipant, b: CallParticipant) -> Bool in
            b.id == "1" && a.id == "2"
        }

        assertSort(
            [
                .dummy(id: "1", name: "Zane"),
                .dummy(id: "2", name: "Aaron")
            ],
            comparator: condition(nameComparator),
            expectedTransformer: { [$0[1], $0[0]] } // Aaron should come before Zane based on the condition.
        )
    }

    /// Test the `id` comparator conditionally based on `name`.
    func test_conditional_idBasedOnName() {
        let condition = conditional { (a: CallParticipant, b: CallParticipant) -> Bool in
            b.name == "Aaron" && a.name == "Zane"
        }

        assertSort(
            [
                .dummy(id: "2", name: "Aaron"),
                .dummy(id: "1", name: "Zane")
            ],
            comparator: condition(id),
            expectedTransformer: { [$0[1], $0[0]] } // ID 1 should come before ID 2 based on the condition.
        )
    }

    /// Test the `userId` comparator conditionally based on both `name` and `id`.
    func test_conditional_userIdBasedOnNameAndId() {
        let condition = conditional { (a: CallParticipant, b: CallParticipant) -> Bool in
            b.name == "Aaron" && a.name == "Zane" && b.id == "1" && a.id == "2"
        }

        assertSort(
            [
                .dummy(id: "1", userId: "B", name: "Aaron"),
                .dummy(id: "2", userId: "A", name: "Zane")
            ],
            comparator: condition(userId),
            expectedTransformer: { [$0[1], $0[0]] } // UserId A should come before UserId B based on the condition.
        )
    }

    // MARK: - ifInvisible

    /// Test the `ifInvisible` comparator with one participant invisible based on `name`.
    func test_ifInvisible_name_oneInvisible() {
        assertSort(
            [
                .dummy(name: "Zane", showTrack: false),
                .dummy(name: "Aaron", showTrack: true)
            ],
            comparator: ifInvisibleBy(nameComparator),
            expectedTransformer: { [$0[1], $0[0]] } // Since Zane is invisible, sorting by name is applied.
        )
    }

    /// Test the `ifInvisible` comparator with both participants invisible based on `name`.
    func test_ifInvisible_name_bothInvisible() {
        assertSort(
            [
                .dummy(name: "Zane", showTrack: false),
                .dummy(name: "Aaron", showTrack: false)
            ],
            comparator: ifInvisibleBy(nameComparator),
            expectedTransformer: { [$0[1], $0[0]] } // Since both are invisible, sorting by name is applied.
        )
    }

    /// Test the `ifInvisible` comparator with both participants visible based on `name`.
    func test_ifInvisible_name_bothVisible() {
        assertSort(
            [
                .dummy(name: "Zane", showTrack: true),
                .dummy(name: "Aaron", showTrack: true)
            ],
            comparator: ifInvisibleBy(nameComparator),
            expectedTransformer: { [$0[0], $0[1]] } // Since both are visible, order remains unchanged.
        )
    }

    // MARK: - defaultComparators

    /// Test the `defaultComparators` mixed: considering both `pinned` and `ifInvisible` for `publishingVideo`.
    func test_defaultComparators_mixed_pinnedAndInvisibleVideo() {
        let combined = combineComparators(defaultSortPreset)

        assertSort(
            [
                .dummy(hasVideo: false, showTrack: false, pin: PinInfo(isLocal: true, pinnedAt: Date())),
                .dummy(hasVideo: true, showTrack: false, pin: nil)
            ],
            comparator: combined,
            expectedTransformer: { [$0[0], $0[1]]
            } // Pinned participant should come first even if the other has video, when both are invisible.
        )
    }

    /// Test the `defaultComparators` mixed: considering `screensharing`, `dominantSpeaker`, and `ifInvisible` for `isSpeaking`.
    func test_defaultComparators_mixed_screenshareDominantAndInvisibleSpeaking() {
        let combined = combineComparators(defaultSortPreset)

        assertSort(
            [
                .dummy(isScreenSharing: true, showTrack: false, isSpeaking: false, isDominantSpeaker: false),
                .dummy(isScreenSharing: false, showTrack: false, isSpeaking: true, isDominantSpeaker: true)
            ],
            comparator: combined,
            expectedTransformer: { [$0[0], $0[1]]
            } // Participant with screen sharing should come first even if the other is a dominant speaker and is speaking, when both are invisible.
        )
    }

    /// Test the `defaultComparators` mixed: considering both `pinned` and `ifInvisible` for `publishingAudio`.
    func test_defaultComparators_mixed_pinnedAndInvisibleAudio() {
        let combined = combineComparators(defaultSortPreset)

        assertSort(
            [
                .dummy(hasAudio: true, showTrack: false, pin: nil),
                .dummy(hasAudio: false, showTrack: false, pin: PinInfo(isLocal: true, pinnedAt: Date()))
            ],
            comparator: combined,
            expectedTransformer: { [$0[1], $0[0]]
            } // Pinned participant should come first even if the other has audio, when both are invisible.
        )
    }

    /// Test the `defaultComparators` mixed: considering `screensharing`, `dominantSpeaker`, `ifInvisible` for `publishingVideo`, and `ifInvisible` for `publishingAudio`.
    func test_defaultComparators_mixed_screenshareDominantInvisibleVideoAndAudio() {
        let combined = combineComparators(defaultSortPreset)

        assertSort(
            [
                .dummy(hasVideo: false, hasAudio: true, isScreenSharing: true, showTrack: false, isDominantSpeaker: false),
                .dummy(hasVideo: true, hasAudio: false, isScreenSharing: false, showTrack: false, isDominantSpeaker: true)
            ],
            comparator: combined,
            expectedTransformer: { [$0[0], $0[1]]
            } // Participant with screen sharing should come first even if the other is a dominant speaker, has video but no audio, when both are invisible.
        )
    }

    func test_defaultComparators_someSpeakingWhileDominantSpeakerIsVisible_orderSetsToShowDominanFirstAndTheOthersSortedBasedOnOtherCriteria(
    ) {
        let combined = combineComparators(defaultSortPreset)

        assertSort(
            [
                .dummy(
                    userId: "A",
                    hasAudio: true,
                    showTrack: false,
                    isSpeaking: true,
                    isDominantSpeaker: false
                ),
                .dummy(
                    userId: "B",
                    hasAudio: true,
                    showTrack: true,
                    isSpeaking: true,
                    isDominantSpeaker: false
                ),
                .dummy(
                    userId: "C",
                    hasAudio: true,
                    showTrack: true,
                    isSpeaking: true,
                    isDominantSpeaker: false
                ),
                .dummy(
                    userId: "D",
                    hasAudio: true,
                    showTrack: false,
                    isSpeaking: true,
                    isDominantSpeaker: true
                )
            ],
            comparator: combined,
            expectedTransformer: { [$0[3], $0[0], $0[1], $0[2]] }
        )
    }

    func test_defaultComparators_someSpeakingWhileDominantSpeakerIsInisible_orderChanges() {
        let combined = combineComparators(defaultSortPreset)

        assertSort(
            [
                .dummy(
                    hasAudio: true,
                    showTrack: true,
                    isSpeaking: true,
                    isDominantSpeaker: false
                ),
                .dummy(
                    hasAudio: true,
                    showTrack: true,
                    isSpeaking: true,
                    isDominantSpeaker: false
                ),
                .dummy(
                    hasAudio: true,
                    showTrack: true,
                    isSpeaking: true,
                    isDominantSpeaker: false
                ),
                .dummy(
                    hasAudio: true,
                    showTrack: false,
                    isSpeaking: true,
                    isDominantSpeaker: true
                )
            ],
            comparator: combined,
            expectedTransformer: { [$0[3], $0[0], $0[1], $0[2]] }
        )
    }

    // MARK: - participantSource

    func test_participantSource_rtmpHasPriority() {
        let subject = participantSource(.rtmp)

        assertSort(
            [
                .dummy(source: .rtmp),
                .dummy(source: .webRTCUnspecified)
            ],
            comparator: subject,
            expectedTransformer: { [$0[0], $0[1]] } // "rtmp" has priority over "webRTCUnspecified".
        )
    }

    func test_participantSource_srtHasPriority() {
        let subject = participantSource(.srt)

        assertSort(
            [
                .dummy(source: .rtmp),
                .dummy(source: .srt)
            ],
            comparator: subject,
            expectedTransformer: { [$0[1], $0[0]] } // "srt" has priority over "rtmp".
        )
    }

    func test_participantSource_sameSource() {
        let subject = participantSource(.rtmp)

        assertSort(
            [
                .dummy(source: .rtmp),
                .dummy(source: .rtmp)
            ],
            comparator: subject,
            expectedTransformer: { [$0[0], $0[1]] }
        )
    }

    // MARK: - Private Helpers

    private func assertSort(
        _ participants: [CallParticipant],
        comparator: StreamSortComparator<CallParticipant>,
        order: StreamSortOrder = .ascending,
        expectedTransformer: @escaping ([CallParticipant]) -> [CallParticipant],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expected = expectedTransformer(participants)
        let actual = participants.sorted(by: comparator, order: order)
        XCTAssertEqual(actual, expected, file: file, line: line)
    }
}

/// This is required as XCTestCase has a `name` property that collides with our `name` comparator
private nonisolated(unsafe) let nameComparator = name
