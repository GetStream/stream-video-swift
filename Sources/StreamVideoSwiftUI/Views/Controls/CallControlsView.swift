//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying call controls such as video toggle, microphone toggle, and participants list button.
public struct CallControlsView: View {

    var viewModel: CallViewModel

    /// Initializes the call controls view with a view model.
    /// - Parameter viewModel: The view model for the call controls.
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack {
            // TODO: Make sure that controls are showing for outgoing calls too
            VideoIconView(viewModel: viewModel)
            MicrophoneIconView(viewModel: viewModel)

            Spacer()

            if viewModel.callingState == .inCall {
                ParticipantsListButton(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .debugViewRendering()
    }
}
