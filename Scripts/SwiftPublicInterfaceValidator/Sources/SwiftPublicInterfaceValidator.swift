//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import ArgumentParser

@main
struct SwiftPublicAPIExtractor: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift CLI tool to extract public APIs.",
        subcommands: [Analysis.self],
        defaultSubcommand: Analysis.self
    )
}
