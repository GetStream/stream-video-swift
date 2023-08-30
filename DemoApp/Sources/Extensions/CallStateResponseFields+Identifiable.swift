//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallStateResponseFields: Identifiable {
    public var id: String {
        call.cid
    }
}
