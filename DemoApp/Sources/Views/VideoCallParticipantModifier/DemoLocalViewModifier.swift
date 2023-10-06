//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoLocalViewModifier: ViewModifier {
        
    var localParticipant: CallParticipant
    var callSettings: Binding<CallSettings>
    var call: Call?
    
    func body(content: Content) -> some View {
        content
            .modifier(
                LocalParticipantViewModifier(
                    localParticipant: localParticipant,
                    callSettings: callSettings
                )
            )
            .modifier(
                ReactionsViewModifier(
                    participant: localParticipant,
                    availableSize: .zero
                )
            )
    }
    
}
