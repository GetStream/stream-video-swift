//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying the speaker toggle button for a call.
public struct SpeakerIconView: View, Equatable {

    var isEnabled: Bool
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the speaker icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the speaker icon.
    ///   - size: The size of the speaker icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        isEnabled = viewModel.call?.state.callSettings.speakerOn ?? false
        self.size = size
        actionHandler = { [weak viewModel] in viewModel?.toggleSpeaker() }
    }

    nonisolated public static func == (
        lhs: SpeakerIconView,
        rhs: SpeakerIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    public var body: some View {
        StatelessSpeakerIconView(
            isEnabled: isEnabled,
            actionHandler: actionHandler
        )
        .equatable()
    }
}
