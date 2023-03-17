//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

public struct ReconnectionView<Factory: ViewFactory>: View {
    
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: CallViewModel
    var viewFactory: Factory
    
    public init(
        viewModel: CallViewModel,
        viewFactory: Factory
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
                    CallingIndicator()
                }
                .padding()
                .background(
                    Color(colors.callBackground).opacity(0.7).edgesIgnoringSafeArea(.all)
                )
                .cornerRadius(16)
            )
    }
}
