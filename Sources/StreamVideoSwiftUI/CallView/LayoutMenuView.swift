//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LayoutMenuView: View, @preconcurrency Equatable {
    @Injected(\.images) var images

    var participantsLayout: ParticipantsLayout
    var size: CGFloat
    var actionHandler: (ParticipantsLayout) -> Void

    public init(
        viewModel: CallViewModel,
        size: CGFloat = 44
    ) {
        participantsLayout = viewModel.participantsLayout
        self.size = size
        actionHandler = { [weak viewModel] in viewModel?.update(participantsLayout: $0) }
    }

    init(
        participantsLayout: ParticipantsLayout,
        size: CGFloat = 44,
        actionHandler: @escaping (ParticipantsLayout) -> Void
    ) {
        self.participantsLayout = participantsLayout
        self.size = size
        self.actionHandler = actionHandler
    }

    public static func == (
        lhs: LayoutMenuView,
        rhs: LayoutMenuView
    ) -> Bool {
        lhs.participantsLayout == rhs.participantsLayout
            && lhs.size == rhs.size
    }

    public var body: some View {
        Menu {
            LayoutMenuItem(
                title: L10n.Call.Current.layoutGrid,
                layout: .grid,
                selectedLayout: participantsLayout,
                selectLayout: actionHandler
            )
            LayoutMenuItem(
                title: L10n.Call.Current.layoutFullScreen,
                layout: .fullScreen,
                selectedLayout: participantsLayout,
                selectLayout: actionHandler
            )
            LayoutMenuItem(
                title: L10n.Call.Current.layoutSpotlight,
                layout: .spotlight,
                selectedLayout: participantsLayout,
                selectLayout: actionHandler
            )
        } label: {
            CallIconView(
                icon: images.layoutSelectorIcon,
                size: size,
                iconStyle: .secondary
            )
        }
    }
}

struct LayoutMenuItem: View {
    
    var title: String
    var layout: ParticipantsLayout
    var selectedLayout: ParticipantsLayout
    var selectLayout: (ParticipantsLayout) -> Void
    
    var body: some View {
        Button {
            withAnimation {
                selectLayout(layout)
            }
        } label: {
            HStack {
                Text(title)
                Spacer()
                if selectedLayout == layout {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}
