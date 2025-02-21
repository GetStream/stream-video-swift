//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

final class ReportBuilder {

    private let storage: Storage
    private let queue = UnfairQueue()
    private var report: String?

    init(_ storage: Storage) {
        self.storage = storage
    }

    func writeReport(for source: URL, to outputURL: URL) throws {
        let content = buildReport(for: source)
        do {
            try content.write(
                to: outputURL,
                atomically: true,
                encoding: .utf8
            )
        } catch {
            print("Failed to write report at:\(outputURL) with error:\(error).")
        }
    }

    func logReport(for source: URL) {
        let content = buildReport(for: source)
        print(content)
    }

    // MARK: - Private Helpers

    private func buildReport(for source: URL) -> String {
        queue.sync {
            if let report = report {
                return report
            }

            var content: [String] = []

            let header = """
            === \(source.lastPathComponent) Public API - Begin (Containers: \(storage.endIndex)) ===
            
            """

            content
                .append(
                    contentsOf: storage
                        .sorted()
                        .map { $0.value.map(\.description).joined() }
                )

            let footer = """
            
            === \(source.lastPathComponent) Public API - End === 
            """

            let result = [
                header,
                content.joined(),
                footer
            ].joined()
            self.report = result
            return result
        }
    }
}
