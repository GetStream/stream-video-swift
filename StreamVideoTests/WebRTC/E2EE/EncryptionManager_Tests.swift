//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class EncryptionManager_Tests: XCTestCase, @unchecked Sendable {

    func test_isSupported() {
        XCTAssertTrue(EncryptionManager.isSupported)
        XCTAssertTrue(RTCEncryptionManager.isSupported())
    }

    func test_init_returnsManager() throws {
        let subject = try EncryptionManager(userId: "user-1")
        XCTAssertEqual(subject.userId, "user-1")
        XCTAssertEqual(subject.algorithm, .aes128Gcm)
        subject.dispose()
    }

    func test_init_rejectsEmptyUserId() {
        XCTAssertThrowsError(try EncryptionManager(userId: ""))
    }

    func test_setSharedKey_rejectsWrongLength() throws {
        let subject = try EncryptionManager(userId: "user-1")
        defer { subject.dispose() }

        XCTAssertThrowsError(
            try subject.setSharedKey(0, rawKey: Data(repeating: 1, count: 8))
        )
    }

    func test_setSharedKey_rejectsInvalidKeyIndex() throws {
        let subject = try EncryptionManager(userId: "user-1")
        defer { subject.dispose() }

        XCTAssertThrowsError(
            try subject.setSharedKey(256, rawKey: Data(repeating: 1, count: 16))
        )
    }

    func test_setSharedKey_acceptsAes128Key() throws {
        let subject = try EncryptionManager(userId: "user-1")
        defer { subject.dispose() }

        try subject.setSharedKey(0, rawKey: Data(repeating: 1, count: 16))
    }

    func test_eventLog_cleartextAndFailures_warn() {
        XCTAssertTrue(e2eeEventLogsAsWarning(.unencryptedFrame))
        XCTAssertTrue(e2eeEventLogsAsWarning(.unsupportedVersion))
        XCTAssertTrue(e2eeEventLogsAsWarning(.encryptionFailed))
        XCTAssertTrue(e2eeEventLogsAsWarning(.decryptionFailed))
        XCTAssertTrue(e2eeEventLogsAsWarning(.missingKey))
        XCTAssertTrue(e2eeEventLogsAsWarning(.decryptionStalled))
    }

    func test_eventLog_keyStateAndPerf_debug() {
        XCTAssertFalse(e2eeEventLogsAsWarning(.keyState))
        XCTAssertFalse(e2eeEventLogsAsWarning(.perfReport))
        XCTAssertFalse(e2eeEventLogsAsWarning(.decryptionResumed))
    }
}
