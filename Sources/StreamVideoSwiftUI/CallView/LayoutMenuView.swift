//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LayoutMenuView: View {
    
    @Injected(\.images) var images

    var viewModel: CallViewModel
    var size: CGFloat

    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        PublisherSubscriptionView(
            initial: viewModel.participantsLayout,
            publisher: viewModel.$participantsLayout.eraseToAnyPublisher()
        ) { participantsLayout in
            Menu {
                LayoutMenuItem(
                    title: L10n.Call.Current.layoutGrid,
                    layout: .grid,
                    selectedLayout: participantsLayout
                ) { layout in
                    viewModel.update(participantsLayout: layout)
                }
                LayoutMenuItem(
                    title: L10n.Call.Current.layoutFullScreen,
                    layout: .fullScreen,
                    selectedLayout: participantsLayout
                ) { layout in
                    viewModel.update(participantsLayout: layout)
                }
                LayoutMenuItem(
                    title: L10n.Call.Current.layoutSpotlight,
                    layout: .spotlight,
                    selectedLayout: participantsLayout
                ) { layout in
                    viewModel.update(participantsLayout: layout)
                }
            } label: {
                CallIconView(
                    icon: images.layoutSelectorIcon,
                    size: size,
                    iconStyle: .secondary
                )
            }
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
