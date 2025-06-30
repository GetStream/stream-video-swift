//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct CallConnectingView<CallControls: View, CallTopView: View, Factory: ViewFactory>: View {
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    @Injected(\.utils) var utils

    var viewFactory: Factory
    var title: String
    var callControls: CallControls
    var callTopView: CallTopView

    @State public var outgoingCallMembers: [Member]

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
        VStack(spacing: 16) {
            headerView
            Spacer()
            middleView
            Spacer()
            footerView
        }
        .background(OutgoingCallBackground(outgoingCallMembers: outgoingCallMembers))
        .onReceive(publisher) { outgoingCallMembers = $0 }
    }

    @ViewBuilder
    var headerView: some View {
        callTopView
    }

    @ViewBuilder
    var middleView: some View {
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
        .padding()

        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(title)
                .applyCallingStyle()
                .accessibility(identifier: "callConnectingView")
            CallingIndicator()
        }
    }

    @ViewBuilder
    var footerView: some View {
        callControls
    }

    var publisher: AnyPublisher<[Member], Never>? {
        streamVideo
            .state
            .ringingCall?
            .state
            .$members
            .compactMap { $0 }
            .map { members in members.filter { $0.id != streamVideo.user.id } }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
