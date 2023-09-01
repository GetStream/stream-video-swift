//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension Call: Identifiable {
    public var id: String { cId }
}
