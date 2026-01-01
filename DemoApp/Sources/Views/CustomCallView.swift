//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct CustomCallView<Factory: ViewFactory>: View {
    
    @Injected(\.colors) var colors
    
    var viewFactory: Factory
    @ObservedObject var viewModel: CallViewModel
    
    @StateObject var microphoneChecker = MicrophoneChecker()
    @State var mutedIndicatorShown = false
    
    var body: some View {
        StreamVideoSwiftUI.CallView(viewFactory: viewFactory, viewModel: viewModel)
            .onReceive(microphoneChecker.$audioLevels, perform: { values in
                guard !viewModel.callSettings.audioOn else { return }
                for value in values {
                    if (value > -50 && value < 0) && !mutedIndicatorShown {
                        mutedIndicatorShown = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            mutedIndicatorShown = false
                        }
                        return
                    }
                }
            })
            .overlay(
                mutedIndicatorShown ?
                    VStack {
                        Spacer()
                        Text("You are muted.")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .foregroundColor(colors.text)
                            .cornerRadius(16)
                            .padding()
                    }
                    : nil
            )
    }
}
