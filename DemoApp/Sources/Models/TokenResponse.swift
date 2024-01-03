//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct TokenResponse: Codable {
    let userId: String
    let token: String
    let apiKey: String
}
