//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct AnimatingParticipantView<Factory: ViewFactory>: View {

    @Injected(\.colors) var colors
    
    @State var isCalling = false

    var viewFactory: Factory
    var participant: Member?
    var caller: String = ""
    
    var body: some View {
        CallingParticipantView(
            viewFactory: viewFactory,
            participant: participant,
            caller: caller
        )
        .scaleEffect(isCalling ? 0.8 : 1)
        .animation(
            .easeOut(duration: 1).repeatForever(autoreverses: true),
            value: isCalling
        )
        .background(
            ZStack {
                // Outer circle
                PulsatingCircle(
                    scaleEffect: isCalling ? 0.8 : 1.2,
                    opacity: 0.2,
                    isCalling: isCalling
                )
                    
                // Middle circle
                PulsatingCircle(
                    scaleEffect: isCalling ? 0.7 : 1.1,
                    opacity: 0.5,
                    isCalling: isCalling
                )
                    
                // Inner circle
                PulsatingCircle(
                    scaleEffect: isCalling ? 0.5 : 1.2,
                    opacity: 0.3,
                    isCalling: isCalling
                )
            }
        )
        .onAppear {
            isCalling.toggle()
        }
    }
}
