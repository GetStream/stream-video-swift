//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view modifier that shows a toast when moderation warnings arrive.
struct ModerationWarningViewModifier: ViewModifier {

    var call: Call?
    var placement: ToastPlacement
    var duration: TimeInterval

    @State var toast: Toast?

    func body(content: Content) -> some View {
        content
            .toastView(toast: $toast)
            .onReceive(
                call?
                    .eventPublisher(for: CallModerationWarningEvent.self)
                    .map {
                        Toast(
                            style: .warning,
                            message: $0.message,
                            placement: placement,
                            duration: duration
                        )
                    }
                    .receive(on: DispatchQueue.main)
            ) { toast = $0 }
    }
}

extension View {

    /// Presents a moderation warning toast driven by moderation events.
    @ViewBuilder
    public func moderationWarning(
        call: Call?,
        placement: ToastPlacement = .top,
        duration: TimeInterval = 2.5
    ) -> some View {
        modifier(
            ModerationWarningViewModifier(
                call: call,
                placement: placement,
                duration: duration
            )
        )
    }
}
