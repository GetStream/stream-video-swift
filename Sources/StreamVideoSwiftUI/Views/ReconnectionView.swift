//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ReconnectionView<Factory: ViewFactory>: View {
    
    @Injected(\.colors) var colors
    
    var viewModel: CallViewModel
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
                VStack {
                    Text(L10n.Call.Current.reconnecting)
                        .applyCallingStyle()
                        .padding()
                        .accessibility(identifier: "reconnectingMessage")
                    CallingIndicator()
                }
                .padding()
                .background(
                    Color(colors.callBackground).opacity(0.7).edgesIgnoringSafeArea(.all)
                )
                .cornerRadius(16)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .debugViewRendering()
    }
}
