//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

public struct LayoutMenuView: View {
    
    @Injected(\.images) var images

    var viewModel: CallViewModel
    var size: CGFloat

    @State var participantsLayout: ParticipantsLayout
    @State var participantsCount: Int
    @State var hideUIElements: Bool

    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
        participantsLayout = viewModel.participantsLayout
        participantsCount = viewModel.callParticipants.count
        hideUIElements = viewModel.hideUIElements
    }
    
    public var body: some View {
        contentView
            .debugViewRendering()
    }

    var participantsLayoutPublisher: AnyPublisher<ParticipantsLayout, Never> {
        viewModel
            .$participantsLayout
            .receive(on: DispatchQueue.global(qos: .utility))
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var participantsCountPublisher: AnyPublisher<Int, Never> {
        viewModel
            .$callParticipants
            .receive(on: DispatchQueue.global(qos: .utility))
            .map(\.count)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    var hideUIElementsPublisher: AnyPublisher<Bool, Never> {
        viewModel
            .$hideUIElements
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    @ViewBuilder
    var contentView: some View {
        if #available(iOS 14.0, *), participantsCount > 1, !hideUIElements {
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
            .onReceive(participantsLayoutPublisher) { participantsLayout = $0 }
            .onReceive(participantsCountPublisher) { participantsCount = $0 }
            .onReceive(hideUIElementsPublisher) { hideUIElements = $0 }
            .accessibility(identifier: "viewMenu")
        }
    }
}
