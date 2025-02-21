//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import ArgumentParser
import Foundation

struct Analysis: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Analyze a directory and generate a public API report."
    )

    @Argument(help: "The directory to analyze.")
    var directoryPath: String

    @Argument(help: "The file path to save the report.")
    var outputPath: String

    private var storage = Storage()

    func run() throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directoryPath) else {
            print("Invalid directory path.")
            return
        }

        let files = discoverFiles(with: "swift", in: directoryPath)

        for fileURL in files {
            let visitor = try ContainerVisitor(fileURL)
            let items = visitor.traverse()
            storage.set(items, for: fileURL)
        }

        let source = URL(fileURLWithPath: directoryPath)
        let outputURL = URL(fileURLWithPath: outputPath)
        let reportBuilder = ReportBuilder(storage)
        try reportBuilder.writeReport(
            for: source,
            to: outputURL
        )
        reportBuilder.logReport(for: source)
    }

    // MARK: Private Helpers

    private func discoverFiles(
        with fileExtension: String,
        in path: String
    ) -> [URL] {
        var result: [URL] = []

        guard
            let enumerator = FileManager.default.enumerator(
                at: .init(filePath: path),
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
        else {
            return result
        }

        for case let fileURL as URL in enumerator {
            do {
                let fileAttributes = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
                if fileAttributes.isRegularFile!, fileURL.pathExtension == fileExtension {
                    result.append(fileURL)
                }
            } catch {
                print(error, fileURL)
            }
        }

        return result
    }
}
