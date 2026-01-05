//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallingParticipantView<Factory: ViewFactory>: View {

    var viewFactory: Factory
    var participant: Member?
    var caller: String = ""
    
    var body: some View {
        ZStack {
            if let participant = participant {
                IncomingCallParticipantView(
                    viewFactory: viewFactory,
                    participant: participant
                )
            } else {
                CircledTitleView(title: caller.isEmpty ? "" : String(caller.uppercased().first!))
            }
        }
    }
}

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

struct PulsatingCircle: View {
    
    @Injected(\.colors) var colors
    var scaleEffect: CGFloat
    var opacity: CGFloat
    var isCalling: Bool
    var size: CGFloat = .expandedAvatarSize
    var animation: Animation = .easeOut(duration: 1).repeatForever(autoreverses: true)
    
    var body: some View {
        Circle()
            .fill(colors.callPulsingColor)
            .frame(width: size, height: size)
            .opacity(opacity)
            .scaleEffect(scaleEffect)
            .animation(animation, value: isCalling)
    }
}

extension CGFloat {
    
    static let expandedAvatarSize: CGFloat = 172
    static let standardAvatarSize: CGFloat = 80
}
