//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoReactionSelectorView: View {

    @Injected(\.reactionsAdapter) var reactionsAdapter
    @Injected(\.images) private var images
    @Injected(\.layout) private var layout

    @ObservedObject private var orientationAdapter = InjectedValues[\.orientationAdapter]
    var closeTapped: () -> Void

    var body: some View {

        HStack(spacing: layout.spacingXs) {
            if orientationAdapter.orientation.isLandscape {
                HStack(spacing: 0) {}
                    .frame(maxWidth: .infinity)
                contentView
                    .frame(maxWidth: .infinity)
                HStack(spacing: 0) {
                    Spacer()
                    ModalButton(image: images.xmark, action: closeTapped)
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
        HStack(alignment: .center, spacing: layout.spacingXs) {
            ForEach(reactionsAdapter.availableReactions.filter { $0 != .raiseHand && $0 != .lowerHand }) { reaction in
                DemoReactionButton(reaction: reaction)
            }
        }
    }
}

@MainActor
struct DemoReactionButton: View {

    @Injected(\.reactionsAdapter) var reactionsAdapter
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    var reaction: Reaction

    var body: some View {
        Button {
            reactionsAdapter.send(reaction: reaction)
        } label: {
            reaction
                .emojiView
                .font(fonts.body)
                .frame(
                    minWidth: layout.buttonVisualHeightMd,
                    minHeight: layout.buttonVisualHeightLg
                )
        }
        .buttonStyle(.plain)
    }
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
