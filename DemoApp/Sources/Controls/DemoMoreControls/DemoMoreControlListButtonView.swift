//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreControlListButtonView: View {

    @Injected(\.colors) var colors

    var centered: Bool = false
    var action: () -> Void
    var label: String
    var icon: () -> Image

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Label(
                    title: { Text(label) },
                    icon: { icon() }
                )

                if !centered {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
        }
        .frame(height: 40)
        .buttonStyle(.borderless)
        .foregroundColor(colors.white)
        .background(Color(colors.participantBackground))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity)
    }
}

@MainActor
struct DemoRaiseHandToggleButtonView: View {

    @ObservedObject var reactionsAdapter = InjectedValues[\.reactionsAdapter]
    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        DemoMoreControlListButtonView(
            centered: true,
            action: { reactionsAdapter.send(reaction: .raiseHand) },
            label: currentUserHasRaisedHand ? "Lower Hand" : "Raise Hand"
        ) {
            Image(
                systemName: currentUserHasRaisedHand
                    ? Reaction.lowerHand.iconName
                    : Reaction.raiseHand.iconName
            )
        }
    }

    private var currentUserHasRaisedHand: Bool {
        guard let userId = viewModel.localParticipant?.userId else {
            return false
        }

        return reactionsAdapter
            .activeReactions[userId]?
            .first(where: { $0.id == .raiseHand }) != nil
    }
}
