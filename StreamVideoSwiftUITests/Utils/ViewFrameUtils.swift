//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The default view controller size. Simulates an iPhone in portrait mode.
let defaultScreenSize = CGSize(width: 360, height: 700)

extension View {    
    func applyDefaultSize() -> some View {
        frame(
            width: defaultScreenSize.width,
            height: defaultScreenSize.height
        )
    }
}
