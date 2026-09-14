//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension EncryptionSettingsResponse {
    static func dummy() -> EncryptionSettingsResponse {
        .init(mode: .disabled)
    }
}
