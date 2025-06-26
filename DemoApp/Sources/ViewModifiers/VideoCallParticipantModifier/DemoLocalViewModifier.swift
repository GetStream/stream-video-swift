//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoLocalViewModifier: ViewModifier {
        
    var localParticipant: CallParticipant
    var call: Call?

    @State var callSettings: CallSettings

    init(
        localParticipant: CallParticipant,
        callSettings: Binding<CallSettings>,
        call: Call? = nil
    ) {
        self.localParticipant = localParticipant
        self.callSettings = callSettings.wrappedValue
        self.call = call
    }

    func body(content: Content) -> some View {
        content
            .modifier(
                LocalParticipantViewModifier(
                    localParticipant: localParticipant,
                    call: call,
                    callSettings: .init(get: { callSettings }, set: { callSettings = $0 }),
                    showAllInfo: true,
                    decorations: [.speaking]
                )
            )
            .modifier(ReactionsViewModifier(participant: localParticipant))
    }
}
