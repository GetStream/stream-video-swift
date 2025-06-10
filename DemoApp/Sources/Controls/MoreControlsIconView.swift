//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideoSwiftUI
import SwiftUI

struct MoreControlsIconView: View, Equatable {

    var isEnabled: Bool
    var size: CGFloat
    var actionHandler: () -> Void

    init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.init(
            isEnabled: viewModel.moreControlsShown,
            size: size,
            actionHandler: { [weak viewModel] in viewModel?.moreControlsShown.toggle() }
        )
    }

    init(
        isEnabled: Bool,
        size: CGFloat = 44,
        actionHandler: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.size = size
        self.actionHandler = actionHandler
    }

    static func == (
        lhs: MoreControlsIconView,
        rhs: MoreControlsIconView
    ) -> Bool {
        lhs.isEnabled == rhs.isEnabled
            && lhs.size == rhs.size
    }

    var body: some View {
        Button(
            action: actionHandler,
            label: {
                CallIconView(
                    icon: Image(systemName: "ellipsis"),
                    size: size,
                    iconStyle: isEnabled ? .secondaryActive : .secondary
                )
                .rotationEffect(.degrees(90))
            }
        )
        .accessibility(identifier: "moreControlsToggle")
    }
}
