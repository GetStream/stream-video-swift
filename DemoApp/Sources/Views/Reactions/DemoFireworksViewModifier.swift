//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import EffectsLibrary
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoFireworksViewModifier: ViewModifier {

    @ObservedObject private var reactionsAdapter = InjectedValues[\.reactionsAdapter]

    func body(content: Self.Content) -> some View {
        content
            .overlay(
                DemoFireworksOverlayView(isVisible: reactionsAdapter.showFireworks)
                    .equatable()
                    .animation(.easeInOut(duration: 0.2), value: reactionsAdapter.showFireworks)
            )
    }
}

extension View {

    func fireworks() -> some View {
        modifier(DemoFireworksViewModifier())
    }
}

private struct DemoFireworksOverlayView: View, Equatable {

    private static let config = FireworksConfig(
        intensity: .high,
        lifetime: .long,
        initialVelocity: .fast
    )

    var isVisible: Bool

    var body: some View {
        ZStack {
            if isVisible {
                FireworksView(config: Self.config)
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
    }
}
