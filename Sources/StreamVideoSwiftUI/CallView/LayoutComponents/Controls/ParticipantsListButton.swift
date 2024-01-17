//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

public struct ParticipantsListButton: View {

    @Injected(\.images) var images
    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel
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
            ControlBadgeView("\(viewModel.callParticipants.count)")
                .opacity(viewModel.callParticipants.count > 1 ? 1 : 0)
        )
        .accessibility(identifier: "participantMenu")
    }
}
