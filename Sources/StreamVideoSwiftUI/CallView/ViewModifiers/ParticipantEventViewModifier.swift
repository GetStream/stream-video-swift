//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

struct ParticipantEventsNotificationViewModifier: ViewModifier {

    @ObservedObject var viewModel: CallViewModel

    func body(content: Content) -> some View {
        content.overlay(overlayContent)
    }

    @ViewBuilder
    private var overlayContent: some View {
        if let event = viewModel.participantEvent {
            Text("\(event.user) \(event.action.display) the call.")
                .font(fonts.body)
                .padding(layout.spacingXs)
                .foregroundColor(Color(colors.textPrimary))
                .modifier(ShadowViewModifier())
                .padding(layout.spacingMd)
                .accessibility(identifier: "participantEventLabel")
        } else {
            EmptyView()
        }
    }
}

extension View {

    /// A viewModifier that displays a notification when a participant event(join or left) occurs.
    @MainActor
    @ViewBuilder
    public func presentParticipantEventsNotification(
        viewModel: CallViewModel
    ) -> some View {
        modifier(ParticipantEventsNotificationViewModifier(viewModel: viewModel))
    }
}
