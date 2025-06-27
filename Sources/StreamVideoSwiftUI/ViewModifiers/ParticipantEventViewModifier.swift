//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

struct ParticipantEventsNotificationViewModifier: ViewModifier {

    @Injected(\.colors) private var colors

    var publisher: AnyPublisher<ParticipantEvent?, Never>

    @State var event: ParticipantEvent?

    init(viewModel: CallViewModel) {
        publisher = viewModel
            .$participantEvent
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func body(content: Content) -> some View {
        content
            .overlay(overlayView)
            .onReceive(publisher) { event = $0 }
            .debugViewRendering()
    }

    @ViewBuilder
    private var overlayView: some View {
        if let event {
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
    @ViewBuilder
    public func presentParticipantEventsNotification(
        viewModel: CallViewModel
    ) -> some View {
        modifier(ParticipantEventsNotificationViewModifier(viewModel: viewModel))
    }
}
