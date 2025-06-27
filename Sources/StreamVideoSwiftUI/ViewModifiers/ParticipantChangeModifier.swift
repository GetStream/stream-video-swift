//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct ParticipantChangeModifier: ViewModifier {
    
    var participant: CallParticipant
    var onChangeTrackVisibility: @MainActor(CallParticipant, Bool) -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 14, *) {
            content
                .onChange(of: participant) { newValue in
                    log.debug("Participant \(newValue.name) is visible")
                    onChangeTrackVisibility(newValue, true)
                }
        } else {
            content
        }
    }
}
