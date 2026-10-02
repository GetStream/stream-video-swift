//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension Image {
    public func customizable() -> some View {
        renderingMode(.template)
            .resizable()
            .scaledToFit()
    }
}
