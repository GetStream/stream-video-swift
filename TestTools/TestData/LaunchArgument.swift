//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public enum LaunchArgument: String {
    case streamTests = "STREAM_TESTS"
    case streamE2ETests = "STREAM_E2E_TESTS"
    case streamSnapshotTests = "STREAM_SNAPSHOT_TESTS"
}

public extension ProcessInfo {
    static func contains(_ argument: LaunchArgument) -> Bool {
        processInfo.arguments.contains(argument.rawValue)
    }
}

public extension XCUIApplication {
    func setLaunchArguments(_ args: LaunchArgument...) {
        launchArguments.append(contentsOf: args.map { $0.rawValue })
    }
}
