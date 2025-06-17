//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct OutgoingCallBackground: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    var outgoingCallMembers: [Member]
    
    var body: some View {
        ZStack {
            if outgoingCallMembers.count == 1 {
                CallBackground(imageURL: outgoingCallMembers.first?.user.imageURL)
            } else {
                FallbackBackground()
            }
        }
    }
}
