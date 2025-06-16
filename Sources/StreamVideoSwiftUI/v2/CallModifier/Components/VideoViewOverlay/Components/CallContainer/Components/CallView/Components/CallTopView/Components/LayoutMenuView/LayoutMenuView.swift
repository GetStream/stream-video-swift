//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct LayoutMenuView: View {

    var viewModel: CallViewModel
    var size: CGFloat

    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }

    public var body: some View {
        if #available(iOS 14.0, *) {
            LayoutMenuContentView(viewModel: viewModel)
        } else {
            EmptyView()
        }
    }
}

@available(iOS 14.0, *)
struct LayoutMenuContentView: View {
    @Injected(\.images) var images

    var viewModel: CallViewModel
    var size: CGFloat
    var actionHandler: (ParticipantsLayout) -> Void

    @State var participantsLayout: ParticipantsLayout
    @State var participantsCount: Int
    @State var isCurrentUserScreenSharing: Bool
    @State var screenSharingSession: ScreenSharingSession?

    public init(
        viewModel: CallViewModel,
        size: CGFloat = 44
    ) {
        self.init(
            viewModel: viewModel,
            participantsLayout: viewModel.participantsLayout,
            size: size,
            actionHandler: { [weak viewModel] in viewModel?.update(participantsLayout: $0) }
        )
    }

    init(
        viewModel: CallViewModel,
        participantsLayout: ParticipantsLayout,
        size: CGFloat = 44,
        actionHandler: @escaping (ParticipantsLayout) -> Void
    ) {
        self.viewModel = viewModel
        self.participantsLayout = participantsLayout
        participantsCount = viewModel.callParticipants.count
        isCurrentUserScreenSharing = viewModel.call?.state.isCurrentUserScreensharing ?? false
        screenSharingSession = viewModel.call?.state.screenSharingSession
        self.size = size
        self.actionHandler = actionHandler
    }

    public var body: some View {
        Group {
            if participantsCount > 1, (screenSharingSession == nil || isCurrentUserScreenSharing) {
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
                .accessibility(identifier: "viewMenu")
            } else {
                EmptyView()
            }
        }
        .onReceive(viewModel.$participantsLayout.removeDuplicates()) { participantsLayout = $0 }
        .onReceive(viewModel.$callParticipants.map(\.count).removeDuplicates()) { participantsCount = $0 }
        .onReceive(viewModel.call?.state.$screenSharingSession) { screenSharingSession = $0 }
        .onReceive(viewModel.call?.state.$isCurrentUserScreensharing) { isCurrentUserScreenSharing = $0 }
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
