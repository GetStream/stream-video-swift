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
        struct SpeakingWhileMutedViewModifier: ViewModifier {

            @Injected(\.colors) var colors
            @ObservedObject var viewModel: CallViewModel

            @State private var mutedIndicatorShown = false
            @State private var mutedIndicatorPresentationID = UUID()

            func body(content: Content) -> some View {
                content
                    .onReceive(speakingWhileMutedPublisher) { isSpeakingWhileMuted in
                        guard isSpeakingWhileMuted else { return }
                        showMutedIndicator()
                    }
                    .overlay(overlayView)
            }

            @ViewBuilder
            private var overlayView: some View {
                if mutedIndicatorShown {
                    VStack {
                        Spacer()
                        Text("You are muted. Unmute to speak.")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .foregroundColor(colors.text)
                            .cornerRadius(16)
                            .padding()
                    }
                }
            }

            private var speakingWhileMutedPublisher: AnyPublisher<Bool, Never> {
                guard let call = viewModel.call else {
                    return Empty().eraseToAnyPublisher()
                }

                return call
                    .state
                    .$isSpeakingWhileMuted
                    .removeDuplicates()
                    .eraseToAnyPublisher()
            }

            private func showMutedIndicator() {
                guard !mutedIndicatorShown else { return }

                let presentationID = UUID()
                mutedIndicatorShown = true
                mutedIndicatorPresentationID = presentationID

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    guard mutedIndicatorPresentationID == presentationID else { return }
                    mutedIndicatorShown = false
                }
            }
        }

        struct CustomCallView<Factory: ViewFactory>: View {

            var viewFactory: Factory
            @ObservedObject var viewModel: CallViewModel

            var body: some View {
                CallView(viewFactory: viewFactory, viewModel: viewModel)
                    .modifier(SpeakingWhileMutedViewModifier(viewModel: viewModel))
            }
        }

        class CustomViewFactory: ViewFactory {

            func makeCallView(viewModel: CallViewModel) -> some View {
                CustomCallView(viewFactory: self, viewModel: viewModel)
            }
        }
    }
}
