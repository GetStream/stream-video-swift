//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension View {

    public func streamAccessibility(value: String) -> some View {
        #if DEBUG
        return self.accessibility(value: Text(value))
        #else
        return self
        #endif
    }
}
