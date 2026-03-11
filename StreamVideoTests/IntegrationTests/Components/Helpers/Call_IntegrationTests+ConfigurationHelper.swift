//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

extension Call_IntegrationTests.Helpers {
    struct ConfigurationHelper: Sendable {
        init(
            webRTCConfiguration: WebRTCConfiguration.Timeout = .production,
            callConfiguration: CallConfiguration.Timeout = .production
        ) {
            // We configure the production timeouts as we hit real endpoints
            WebRTCConfiguration.timeout = webRTCConfiguration
            CallConfiguration.timeout = callConfiguration
        }
    }
}
