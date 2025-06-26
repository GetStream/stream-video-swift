//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// A view displaying the speaker toggle button for a call.
public struct SpeakerIconView: View {

    weak var call: Call?
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the speaker icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the speaker icon.
    ///   - size: The size of the speaker icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        actionHandler = { [weak viewModel] in viewModel?.toggleSpeaker() }
    }

    public var body: some View {
        StatelessSpeakerIconView(
            call: call,
            actionHandler: actionHandler
        )
        .debugViewRendering()
    }
}
