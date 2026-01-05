//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    container {
        struct CustomCallView<Factory: ViewFactory>: View {

            @Injected(\.colors) var colors

            var viewFactory: Factory
            @ObservedObject var viewModel: CallViewModel

            @StateObject var microphoneChecker = MicrophoneChecker()
            @State var mutedIndicatorShown = false

            var body: some View {
                CallView(viewFactory: viewFactory, viewModel: viewModel)
                    .onReceive(viewModel.$callSettings) { _ in
                        Task { await updateMicrophoneChecker() }
                    }
                    .onReceive(microphoneChecker.$audioLevels, perform: { values in
                        guard !viewModel.callSettings.audioOn else { return }
                        for value in values {
                            if (value > -50 && value < 0) && !mutedIndicatorShown {
                                mutedIndicatorShown = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                                    mutedIndicatorShown = false
                                })
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

            private func updateMicrophoneChecker() async {
                if !viewModel.callSettings.audioOn {
                    await microphoneChecker.startListening()
                } else {
                    await microphoneChecker.stopListening()
                }
            }
        }

        class CustomViewFactory: ViewFactory {

            func makeCallView(viewModel: CallViewModel) -> some View {
                CustomCallView(viewFactory: self, viewModel: viewModel)
            }
        }
    }
}
