//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension Call: @retroactive Identifiable {
    public var id: String { cId }
}
