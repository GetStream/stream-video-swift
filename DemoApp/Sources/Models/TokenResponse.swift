//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

struct TokenResponse: Codable, ReflectiveStringConvertible {
    let userId: String
    let token: String
    let apiKey: String
}
