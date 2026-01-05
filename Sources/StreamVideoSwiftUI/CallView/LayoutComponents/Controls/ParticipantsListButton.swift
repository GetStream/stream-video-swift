//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A button that can be used to present toggle the Participants List's presentation. Additionally, it will
/// display a badge with the number of the total participants in the call.
public struct ParticipantsListButton: View {

    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel
    @State private var count: Int = 0
    let size: CGFloat

    public init(
        viewModel: CallViewModel,
        size: CGFloat = 44
    ) {
        self.viewModel = viewModel
        self.size = size
    }

    public var body: some View {
        StatelessParticipantsListButton(
            call: viewModel.call,
            isActive: $viewModel.participantsShown
        ) { [weak viewModel] in viewModel?.participantsShown = true }
    }
}
