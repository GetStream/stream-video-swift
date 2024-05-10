//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallConnectingView<CallControls: View, CallTopView: View>: View {
    @Injected(\.streamVideo) var streamVideo
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.utils) var utils
    
    public var outgoingCallMembers: [Member]
    public var title: String
    public var callControls: CallControls
    public var callTopView: CallTopView

    public init(
        outgoingCallMembers: [Member],
        title: String,
        callControls: CallControls,
        callTopView: CallTopView
    ) {
        self.outgoingCallMembers = outgoingCallMembers
        self.title = title
        self.callControls = callControls
        self.callTopView = callTopView
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 16) {
                callTopView
                
                Spacer()
                
                if outgoingCallMembers.count > 1 {
                    CallingGroupView(
                        participants: outgoingCallMembers
                    )
                    .accessibilityElement(children: .combine)
                    .accessibility(identifier: "callConnectingGroupView")
                } else if !outgoingCallMembers.isEmpty {
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
