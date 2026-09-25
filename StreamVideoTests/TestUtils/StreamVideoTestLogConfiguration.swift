//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

@_cdecl("stream_video_test_configure_logging")
func configureStreamVideoTestLogging() {
    let isVerbose =
        ProcessInfo.processInfo.environment["STREAM_TEST_VERBOSE"] == "true"
    LogConfig.level = isVerbose ? .debug : .error
    if isVerbose {
        LogConfig.destinationTypes = [ConsoleLogDestination.self]
    }
}
