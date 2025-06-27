//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct PinnedView: View {
    var isPinned: Bool
    var maxHeight: Float

    var body: some View {
        if isPinned {
            Image(systemName: "pin.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: CGFloat(maxHeight))
                .foregroundColor(.white)
                .padding(.trailing, 4)
                .debugViewRendering()
        }
    }
}
