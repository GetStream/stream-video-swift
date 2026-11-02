//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import XCTest

final class LogQueue_Tests: XCTestCase, @unchecked Sendable {
    private var directory: URL!
    private var subject: SessionLogFile!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDownWithError() throws {
        subject = nil
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
        directory = nil
    }

    func test_insert_overCapacity_keepsNewestEntriesInOrder() {
        let subject = Queue<Int>(maxCount: 3)
        for value in 0..<10 {
            subject.insert(value)
        }

        XCTAssertEqual(subject.elements, [9, 8, 7])
    }

    func test_insert_zeroCapacity_keepsNoEntries() {
        let subject = Queue<Int>(maxCount: 0)
        subject.insert(1)

        XCTAssertTrue(subject.elements.isEmpty)
    }

    func test_append_export_preservesAllEntriesInOrder() async throws {
        subject = try SessionLogFile(directory: directory)
        let entries = (0..<15000).map { "entry-\($0)" }
        for entry in entries {
            subject.append(entry + "\n")
        }

        let url = try await subject.export()
        defer { try? FileManager.default.removeItem(at: url) }
        let content = try String(contentsOf: url, encoding: .utf8)
        XCTAssertEqual(
            content.split(separator: "\n").dropFirst().map(String.init),
            entries
        )
    }

    func test_rotation_export_recoversOnlyCurrentAndPreviousSessions()
        async throws {
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        try Data("previous-session\n".utf8).write(
            to: directory.appendingPathComponent("current.txt")
        )
        try Data("obsolete-session\n".utf8).write(
            to: directory.appendingPathComponent("previous.txt")
        )
        subject = try SessionLogFile(directory: directory)
        subject.append("current-session\n")
        let firstURL = try await subject.export()
        defer { try? FileManager.default.removeItem(at: firstURL) }
        let firstContent = try String(contentsOf: firstURL, encoding: .utf8)
        XCTAssertTrue(firstContent.hasPrefix("previous-session\n"))
        XCTAssertTrue(firstContent.hasSuffix("current-session\n"))
        XCTAssertFalse(firstContent.contains("obsolete-session"))

        subject = nil
        subject = try SessionLogFile(directory: directory)
        subject.append("new-session\n")
        let secondURL = try await subject.export()
        defer { try? FileManager.default.removeItem(at: secondURL) }
        let secondContent = try String(contentsOf: secondURL, encoding: .utf8)
        XCTAssertTrue(secondContent.contains("current-session\n"))
        XCTAssertTrue(secondContent.hasSuffix("new-session\n"))
        XCTAssertFalse(secondContent.contains("previous-session\n"))
        XCTAssertEqual(
            Set(try FileManager.default.contentsOfDirectory(
                atPath: directory.path
            )),
            ["current.txt", "previous.txt"]
        )
    }

    func test_concurrentAppendAndSnapshot_preservesEntriesAndCapacity()
        async throws {
        subject = try SessionLogFile(directory: directory)
        let file = try XCTUnwrap(subject)
        let ring = Queue<Int>(maxCount: 100)
        DispatchQueue.concurrentPerform(iterations: 1000) { value in
            ring.insert(value)
            file.append("entry-\(value)\n")
            XCTAssertLessThanOrEqual(ring.elements.count, 100)
        }

        let url = try await file.export()
        defer { try? FileManager.default.removeItem(at: url) }
        let content = try String(contentsOf: url, encoding: .utf8)
        let entries = content.split(separator: "\n").dropFirst()
        XCTAssertEqual(Set(entries).count, 1000)
        XCTAssertEqual(entries.count, 1000)
        XCTAssertEqual(Set(ring.elements).count, 100)
    }

    func test_append_timer_persistsWithoutExport() throws {
        subject = try SessionLogFile(directory: directory)
        subject.append("recover-without-export\n")
        let url = directory.appendingPathComponent("current.txt")

        AssertAsync.willBeTrue(
            (try? String(contentsOf: url, encoding: .utf8))?
                .contains("recover-without-export\n") == true,
            timeout: 3
        )
    }

    func test_init_fileInsteadOfDirectory_throws() throws {
        try Data().write(to: directory)

        XCTAssertThrowsError(try SessionLogFile(directory: directory))
    }
}
