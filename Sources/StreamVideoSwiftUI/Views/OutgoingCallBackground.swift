//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct OutgoingCallBackground: View {

    var outgoingCallMembers: [Member]
    
    var body: some View {
        contentView
            .debugViewRendering()
    }

    @ViewBuilder
    var contentView: some View {
        if outgoingCallMembers.count == 1 {
            CallBackground(imageURL: outgoingCallMembers.first?.user.imageURL)
        } else {
            FallbackBackground()
        }
    }
}
