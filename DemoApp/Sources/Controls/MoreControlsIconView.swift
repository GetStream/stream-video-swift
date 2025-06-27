//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct MoreControlsIconView: View {

    var viewModel: CallViewModel
    let size: CGFloat

    @State var isActive: Bool
    var isActivePublisher: AnyPublisher<Bool, Never>

    init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size

        isActive = viewModel.moreControlsShown
        isActivePublisher = viewModel
            .$moreControlsShown
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var body: some View {
        Button(
            action: {
                viewModel.moreControlsShown.toggle()
            },
            label: {
                CallIconView(
                    icon: Image(systemName: "ellipsis"),
                    size: size,
                    iconStyle: isActive ? .secondaryActive : .secondary
                )
                .rotationEffect(.degrees(90))
            }
        )
        .accessibility(identifier: "moreControlsToggle")
        .onReceive(isActivePublisher) { isActive = $0 }
    }
}
