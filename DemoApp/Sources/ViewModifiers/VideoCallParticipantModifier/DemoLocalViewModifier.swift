//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoLocalViewModifier: ViewModifier {
        
    var localParticipant: CallParticipant
    var callSettings: Binding<CallSettings>
    var call: Call?
    
    func body(content: Content) -> some View {
        content
            .modifier(
                LocalParticipantViewModifier(
                    localParticipant: localParticipant,
                    call: call,
                    callSettings: callSettings,
                    showAllInfo: true,
                    decorations: [.speaking]
                )
            )
            .modifier(ReactionsViewModifier(participant: localParticipant))
    }
}
