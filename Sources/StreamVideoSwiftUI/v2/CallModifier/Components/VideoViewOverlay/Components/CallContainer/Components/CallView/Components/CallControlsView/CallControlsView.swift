//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying call controls such as video toggle, microphone toggle, and participants list button.
public struct CallControlsView: View {
    let viewModel: CallViewModel
    @State var showParticipantsList: Bool

    /// Initializes the call controls view with a view model.
    /// - Parameter viewModel: The view model for the call controls.
    public init(viewModel: CallViewModel) {
        showParticipantsList = viewModel.callingState == .inCall
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack {
            VideoIconView(viewModel: viewModel)
            MicrophoneIconView(viewModel: viewModel)
            
            Spacer()

            if showParticipantsList {
                ParticipantsListButton(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .onReceive(
            viewModel
                .$callingState
                .removeDuplicates()
                .map { $0 == .inCall }
        ) { showParticipantsList = $0 }
    }
}
