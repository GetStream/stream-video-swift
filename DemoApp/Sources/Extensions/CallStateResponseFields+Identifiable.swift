//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallStateResponseFields: Identifiable {
    public var id: String {
        call.cid
    }
}
