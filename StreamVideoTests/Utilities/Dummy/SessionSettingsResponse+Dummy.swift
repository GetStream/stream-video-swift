//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension SessionSettingsResponse {
    static func dummy(inactivityTimeoutSeconds: Int = 10) -> SessionSettingsResponse {
        SessionSettingsResponse(inactivityTimeoutSeconds: inactivityTimeoutSeconds)
    }
}
