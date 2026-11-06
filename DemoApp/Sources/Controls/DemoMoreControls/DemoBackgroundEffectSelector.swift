//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@available(iOS 15.0, *)
struct DemoBackgroundEffectSelector: View {

    var effects: [BackgroundEffect] = BackgroundEffect.allCases

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center) {
                ForEach(effects) { effect in
                    DemoEffectButton(effect: effect)
                }
            }
            .padding(8)
        }
    }
}

@available(iOS 15.0, *)
@MainActor
struct DemoEffectButton: View {

    @Injected(\.colors) var colors

    var effect: BackgroundEffect
    @ObservedObject var appState = AppState.shared

    private var isSelected: Bool {
        switch effect {
        case .none:
            return appState.videoFilter == nil
        case .pixelate:
            return appState.videoFilter?.id == VideoFilter.pixelate.id
        case .blur:
            return appState.videoFilter?.id == VideoFilter.blur.id
        case .blurBackground:
            return appState.videoFilter?.id == VideoFilter.blurredBackground.id
        default:
            return appState.videoFilter?.id == effect.rawValue
        }
    }

    var body: some View {
        Button {
            appState.videoFilter = isSelected ? nil : effect.filter
        } label: {
            Circle()
                .fill(Color(colors.participantBackground))
                .overlay(
                    effect
                        .image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(effect.padding)
                        .clipShape(Circle())
                )
                .clipped()
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(isSelected ? colors.text : .clear))
        }
        .buttonStyle(.plain)
    }
}
