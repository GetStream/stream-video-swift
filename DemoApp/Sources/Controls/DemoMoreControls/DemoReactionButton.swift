//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoReactionSelectorView: View {

    var reactions: [Reaction] = [
        .like,
        .fireworks,
        .dislike,
        .heart,
        .hello
    ]

    @Injected(\.images) private var images

    @State private var showsCloseButton = false
    var closeTapped: () -> Void

    var body: some View {

        HStack {
            if showsCloseButton {
                HStack {  }
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
        .onRotate { orientation in
            showsCloseButton = !orientation.isPortrait && UIDevice.current.userInterfaceIdiom == .phone
        }
    }

    @ViewBuilder
    private var contentView: some View {
        HStack(alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/) {
            ForEach(reactions) { reaction in
                DemoReactionButton(reaction: reaction)
            }
        }
    }
}

@MainActor
struct DemoReactionButton: View {

    @Injected(\.colors) var colors

    var reaction: Reaction
    var reactionsHelper = AppState.shared.reactionsHelper

    var body: some View {
        Button {
            reactionsHelper.send(reaction: reaction)
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
