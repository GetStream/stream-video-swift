//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension View {

    public func streamAccessibility(value: String) -> some View {
        #if DEBUG
        return accessibility(value: Text(value))
        #else
        return self
        #endif
    }
}
