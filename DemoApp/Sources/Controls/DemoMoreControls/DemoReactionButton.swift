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
        HStack(alignment: .center) {
            ForEach(reactionsAdapter.availableReactions.filter { $0 != .raiseHand && $0 != .lowerHand }) { reaction in
                DemoReactionButton(reaction: reaction)
            }
        }
    }
}

@MainActor
struct DemoReactionButton: View {

    @Injected(\.colors) var colors
    @Injected(\.reactionsAdapter) var reactionsAdapter

    var reaction: Reaction

    var body: some View {
        Button {
            reactionsAdapter.send(reaction: reaction)
        } label: {
            Circle()
                .fill(Color(colors.participantBackground))
                .overlay(
                    reaction
                        .emojiView
                        .font(.body)
                        .aspectRatio(contentMode: .fit)
                        .padding(10)
                )
                .frame(width: 44, height: 44)
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
