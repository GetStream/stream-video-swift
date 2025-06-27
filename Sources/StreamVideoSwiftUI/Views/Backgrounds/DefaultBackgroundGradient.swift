//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct DefaultBackgroundGradient: View {
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 60 / 255, green: 64 / 255, blue: 72 / 255),
                Color(red: 30 / 255, green: 33 / 255, blue: 36 / 255)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
