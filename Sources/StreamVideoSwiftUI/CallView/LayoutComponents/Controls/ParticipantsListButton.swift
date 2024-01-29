//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

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
        Button(
            action: {
                viewModel.participantsShown = true
            },
            label: {
                CallIconView(
                    icon: images.participantsIcon,
                    size: size,
                    iconStyle: viewModel.participantsShown ? .secondaryActive : .secondary
                )
            }
        )
        .overlay(
            ControlBadgeView("\(count)")
                .opacity(count > 1 ? 1 : 0)
        )
        .accessibility(identifier: "participantMenu")
        .onReceive(viewModel.call?.state.$participants) {
            // We use the participants array in order to access the count of
            // Participants in an O(1) operation.
            count = $0.endIndex
        }
    }
}
