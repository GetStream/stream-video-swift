//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct LayoutMenuView: View {
    
    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    var size: CGFloat

    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        _viewModel = ObservedObject(initialValue: viewModel)
        self.size = size
    }
    
    public var body: some View {
        Menu {
            LayoutMenuItem(
                title: L10n.Call.Current.layoutGrid,
                layout: .grid,
                selectedLayout: viewModel.participantsLayout
            ) { layout in
                viewModel.update(participantsLayout: layout)
            }
            LayoutMenuItem(
                title: L10n.Call.Current.layoutFullScreen,
                layout: .fullScreen,
                selectedLayout: viewModel.participantsLayout
            ) { layout in
                viewModel.update(participantsLayout: layout)
            }
            LayoutMenuItem(
                title: L10n.Call.Current.layoutSpotlight,
                layout: .spotlight,
                selectedLayout: viewModel.participantsLayout
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
