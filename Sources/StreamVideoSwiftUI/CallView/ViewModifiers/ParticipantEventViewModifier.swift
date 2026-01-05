//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

struct ParticipantEventsNotificationViewModifier: ViewModifier {

    @Injected(\.colors) private var colors

    @ObservedObject var viewModel: CallViewModel

    func body(content: Content) -> some View {
        content.overlay(overlayContent)
    }

    @ViewBuilder
    private var overlayContent: some View {
        if let event = viewModel.participantEvent {
            Text("\(event.user) \(event.action.display) the call.")
                .padding(8)
                .background(Color(UIColor.systemBackground))
                .foregroundColor(colors.text)
                .modifier(ShadowViewModifier())
                .padding()
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
