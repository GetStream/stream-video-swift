//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public enum EnvironmentVariable: String {
    case jwtExpiration = "JWT_EXPIRATION"
}

public enum LaunchArgument: String {
    case mockJwt = "MOCK_JWT"
    case invalidateJwt = "INVALIDATE_JWT"
    case breakJwt = "BREAK_JWT"
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

    func setEnvironmentVariables(_ envVars: [EnvironmentVariable: String]) {
        envVars.forEach { envVar in
            launchEnvironment[envVar.key.rawValue] = envVar.value
        }
    }
}
