//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

struct CallingGroupView: View {
    
    let easeGently = Animation.easeOut(duration: 1).repeatForever(autoreverses: true)
    
    var participants: [Member]
    @State var isCalling = false
    
    var body: some View {
        VStack {
            if participants.count >= 3 {
                IncomingCallParticipantView(
                    participant: participants[0],
                    size: .standardAvatarSize
                )
                .background(
                    PulsatingCircle(
                        scaleEffect: isCalling ? 1.2 : 0.8,
                        opacity: 0.5,
                        isCalling: isCalling,
                        size: .standardAvatarSize,
                        animation: easeGently.delay(0.2)
                    )
                )
                HStack(spacing: 16) {
                    IncomingCallParticipantView(
                        participant: participants[1],
                        size: .standardAvatarSize
                    )
                    .background(
                        PulsatingCircle(
                            scaleEffect: isCalling ? 1.2 : 0.7,
                            opacity: 0.5,
                            isCalling: isCalling,
                            size: .standardAvatarSize,
                            animation: easeGently.delay(0.4)
                        )
                    )
                    
                    ZStack {
                        if participants.count == 3 {
                            IncomingCallParticipantView(
                                participant: participants[2],
                                size: .standardAvatarSize
                            )
                        } else {
                            CircledTitleView(
                                title: "+\(participants.count - 2)",
                                size: .standardAvatarSize
                            )
                        }
                    }
                    .background(
                        PulsatingCircle(
                            scaleEffect: isCalling ? 1.2 : 0.5,
                            opacity: 0.5,
                            isCalling: isCalling,
                            size: .standardAvatarSize,
                            animation: easeGently.delay(0.6)
                        )
                    )
                }
            } else {
                HStack(spacing: 16) {
                    ForEach(0..<participants.count, id: \.self) { index in
                        let participant = participants[index]
                        IncomingCallParticipantView(
                            participant: participant,
                            size: .standardAvatarSize
                        )
                        .background(
                            PulsatingCircle(
                                scaleEffect: isCalling ? 1.2 : 0.5,
                                opacity: 0.5,
                                isCalling: isCalling,
                                size: .standardAvatarSize,
                                animation: easeGently.delay(0.2 + Double(index) * 0.2)
                            )
                        )
                    }
                }
            }
        }
        .onAppear {
            isCalling.toggle()
        }
    }
}

struct IncomingCallParticipantView: View {
        
    var participant: Member
    var size: CGFloat = .expandedAvatarSize
    
    var body: some View {
        ZStack {
            if #available(iOS 14.0, *), let imageURL = participant.user.imageURL {
                UserAvatar(imageURL: imageURL, size: size)
            } else {
                let name = participant.user.name.isEmpty ? "Unknown" : participant.user.name
                let title = String(name.uppercased().first!)
                CircledTitleView(title: title, size: size)
            }
        }
        .frame(width: size, height: size)
        .modifier(ShadowModifier())
        .animation(nil)
    }
}

struct CircledTitleView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    
    var title: String
    var size: CGFloat = .expandedAvatarSize
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(colors.tintColor)
            Text(title)
                .foregroundColor(.white)
                .font(fonts.title)
                .padding()
        }
        .frame(maxWidth: size, maxHeight: size)
        .modifier(ShadowModifier())
    }
}
