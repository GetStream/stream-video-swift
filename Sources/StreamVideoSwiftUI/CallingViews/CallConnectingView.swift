//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

struct CallConnectingView<CallControls: View, CallTopView: View>: View {
    @Injected(\.streamVideo) var streamVideo
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    var outgoingCallMembers: [Member]
    var title: String
    var callControls: CallControls
    var callTopView: CallTopView

    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                callTopView
                
                Spacer()
                
                if outgoingCallMembers.count > 1 {
                    CallingGroupView(
                        participants: outgoingCallMembers
                    )
                    .accessibility(identifier: "callConnectingGroupView")
                } else if outgoingCallMembers.count > 0 {
                    AnimatingParticipantView(
                        participant: outgoingCallMembers.first
                    )
                    .accessibility(identifier: "callConnectingParticipantView")
                }
                
                CallingParticipantsView(
                    participants: outgoingCallMembers
                )
                .padding()
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(title)
                        .applyCallingStyle()
                        .accessibility(identifier: "callConnectingView")
                    CallingIndicator()
                }
                
                Spacer()
                
                callControls
            }
        }
        .background(
            OutgoingCallBackground(outgoingCallMembers: outgoingCallMembers)
        )
    }
}
