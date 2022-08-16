//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

struct CallingGroupView: View {
        
    var participants: [CallParticipant]
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Spacer()
                if participants.count > 3 {
                    IncomingCallParticipantView(participant: participants[0])
                    IncomingCallParticipantView(participant: participants[1])
                    CircledTitleView(title: "+\(participants.count - 2)")
                } else {
                    ForEach(participants) { participant in
                        IncomingCallParticipantView(participant: participant)
                    }
                }
                Spacer()
            }
        }
    }
}

struct IncomingCallParticipantView: View {
        
    var participant: CallParticipant
    
    var body: some View {
        ZStack {
            if let imageURL = participant.profileImageURL {
                LazyImage(source: imageURL)
                    .clipShape(Circle())
            } else {
                let name = participant.name.isEmpty ? "Unknown" : participant.name
                let title = String(name.uppercased().first!)
                CircledTitleView(title: title)
            }
        }
        .frame(width: 80, height: 80)
        .modifier(ShadowModifier())
    }
}

struct CircledTitleView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    
    var title: String
    
    var body: some View {
        ZStack {
            Circle()
                .foregroundColor(colors.tintColor)
            Text(title)
                .foregroundColor(.white)
                .font(fonts.title)
        }
        .frame(width: 80, height: 80)
        .modifier(ShadowModifier())
    }
}
