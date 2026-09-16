//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import StreamVideo
import SwiftUI

public struct CallConnectingView<CallControls: View, CallTopView: View, Factory: ViewFactory>: View {
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.videoAppearance) var videoAppearance

    var viewFactory: Factory
    @State public var outgoingCallMembers: [Member]
    public var title: String
    public var callControls: CallControls
    public var callTopView: CallTopView

    public init(
        viewFactory: Factory = DefaultViewFactory.shared,
        outgoingCallMembers: [Member],
        title: String,
        callControls: CallControls,
        callTopView: CallTopView
    ) {
        self.viewFactory = viewFactory
        self.outgoingCallMembers = outgoingCallMembers
        self.title = title
        self.callControls = callControls
        self.callTopView = callTopView
    }

    public var body: some View {
        ZStack {
            VStack(spacing: tokens.layout.spacingMd) {
                callTopView
                
                Spacer()
                
                if outgoingCallMembers.count > 1 {
                    CallingGroupView(
                        viewFactory: viewFactory,
                        participants: outgoingCallMembers
                    )
                    .accessibilityElement(children: .combine)
                    .accessibility(identifier: "callConnectingGroupView")
                } else if !outgoingCallMembers.isEmpty {
                    AnimatingParticipantView(
                        viewFactory: viewFactory,
                        participant: outgoingCallMembers.first
                    )
                    .accessibility(identifier: "callConnectingParticipantView")
                }
                
                CallingParticipantsView(
                    participants: outgoingCallMembers
                )
                .padding(tokens.layout.spacingMd)
                
                HStack(alignment: .firstTextBaseline, spacing: tokens.layout.spacingXxxs) {
                    Text(title)
                        .font(tokens.fonts.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(
                            Color(tokens.colors.textSecondary)
                        )
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
        .onReceive(streamVideo.state.ringingCall?.state.$members.receive(on: DispatchQueue.main)) { members in
            outgoingCallMembers = members.filter { $0.id != streamVideo.user.id }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
