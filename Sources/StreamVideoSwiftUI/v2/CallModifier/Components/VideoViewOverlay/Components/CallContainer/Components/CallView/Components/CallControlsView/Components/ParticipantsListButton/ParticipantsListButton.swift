//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A button that can be used to present toggle the Participants List's presentation. Additionally, it will
/// display a badge with the number of the total participants in the call.
public struct ParticipantsListButton: View {

    var viewModel: CallViewModel
    var size: CGFloat
    @State var count: Int
    @State var isActive: Bool

    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
        count = viewModel.callParticipants.count
        isActive = viewModel.participantsShown
    }

    public var body: some View {
        StatelessParticipantsListButton(
            count: count,
            size: size,
            isActive: isActive,
            actionHandler: { [weak viewModel] in viewModel?.participantsShown = true }
        )
        .onReceive(
            viewModel
                .call?
                .state
                .$participants
                .map(\.endIndex)
                .removeDuplicates()
        ) { count = $0 }
        .onReceive(
            viewModel
                .$participantsShown
                .removeDuplicates()
        ) { isActive = $0 }
    }
}
