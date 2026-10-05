//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ReconnectionView<Factory: ViewFactory>: View {
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.layout) var layout
    
    @ObservedObject var viewModel: CallViewModel
    var viewFactory: Factory
    
    public init(
        viewModel: CallViewModel,
        viewFactory: Factory = DefaultViewFactory.shared
    ) {
        self.viewModel = viewModel
        self.viewFactory = viewFactory
    }
    
    public var body: some View {
        WaitingLocalUserView(viewModel: viewModel, viewFactory: viewFactory)
            .overlay(
                VStack(spacing: layout.spacingXs) {
                    Text(L10n.Call.Current.reconnecting)
                        .font(fonts.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(colors.textPrimary))
                        .padding(layout.spacingMd)
                        .accessibility(identifier: "reconnectingMessage")
                    CallingIndicator()
                }
                .padding(layout.spacingMd)
                .background(
                    Color(colors.backgroundCoreSurfaceCard).edgesIgnoringSafeArea(.all)
                )
                .cornerRadius(layout.radiusXl)
            )
    }
}
