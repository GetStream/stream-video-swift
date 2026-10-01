//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoSpeakingWhileMutedViewModifier: ViewModifier {

    @Injected(\.videoAppearance) private var videoAppearance
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
            VStack(spacing: 0) {
                Spacer()
                Text("You are muted. Unmute to speak.")
                    .padding(tokens.layout.spacingXs)
                    .background(Color(tokens.colors.backgroundCoreElevation1))
                    .foregroundColor(Color(tokens.colors.textPrimary))
                    .cornerRadius(tokens.layout.radiusXl)
                    .padding(tokens.layout.spacingMd)
            }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }

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
