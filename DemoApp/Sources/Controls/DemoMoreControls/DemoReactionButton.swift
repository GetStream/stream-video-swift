//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoReactionSelectorView: View {

    @Injected(\.reactionsAdapter) var reactionsAdapter
    @Injected(\.videoAppearance) private var videoAppearance

    @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]
    var closeTapped: () -> Void

    var body: some View {

        HStack {
            if orientationAdapter.orientation.isLandscape {
                HStack {}
                    .frame(maxWidth: .infinity)
                contentView
                    .frame(maxWidth: .infinity)
                HStack {
                    Spacer()
                    ModalButton(image: videoAppearance.images.xmark, action: closeTapped)
                        .accessibility(identifier: "Close")
                }
                .frame(maxWidth: .infinity)
            } else {
                contentView
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        HStack(alignment: .center, spacing: tokens.layout.spacingXs) {
            ForEach(reactionsAdapter.availableReactions.filter { $0 != .raiseHand && $0 != .lowerHand }) { reaction in
                DemoReactionButton(reaction: reaction)
            }
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

@MainActor
struct DemoReactionButton: View {

    @Injected(\.videoAppearance) private var videoAppearance
    @Injected(\.reactionsAdapter) var reactionsAdapter

    var reaction: Reaction

    var body: some View {
        Button {
            reactionsAdapter.send(reaction: reaction)
        } label: {
            reaction
                .emojiView
                .font(tokens.fonts.body)
                .frame(
                    minWidth: tokens.layout.buttonVisualHeightMd,
                    minHeight: tokens.layout.buttonVisualHeightLg
                )
        }
        .buttonStyle(.plain)
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}

extension Reaction {

    @ViewBuilder
    var emojiView: some View {
        switch self {
        case .fireworks:
            Text("🎉")
        case .like:
            Text("👍")
        case .dislike:
            Text("👎")
        case .heart:
            Text("❤️")
        case .smile:
            Text("😃")
        case .hello:
            Text("👋")
        default:
            EmptyView()
        }
    }
}
