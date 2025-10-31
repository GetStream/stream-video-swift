//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view modifier that blurs a participant when moderation blur toggles.
struct ModerationBlurViewModifier: ViewModifier {

    var call: Call?
    var participant: CallParticipant
    var blurRadius: Float

    @State var isBlurred: Bool = true

    func body(content: Content) -> some View {
        Group {
            if isBlurred {
                content
                    .blur(radius: .init(blurRadius))
            } else {
                content
            }
        }
        .onReceive(
            call?
                .eventPublisher(for: CallModerationBlurEvent.self)
                .filter { $0.userId == participant.userId }
                .map { _ in !isBlurred }
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
        ) { isBlurred = $0 }
    }
}

extension View {

    /// Applies a moderation blur effect that responds to moderation events.
    @ViewBuilder
    public func moderationBlur(
        call: Call?,
        participant: CallParticipant,
        blurRadius: Float = 30
    ) -> some View {
        modifier(
            ModerationBlurViewModifier(
                call: call,
                participant: participant,
                blurRadius: blurRadius
            )
        )
    }
}
