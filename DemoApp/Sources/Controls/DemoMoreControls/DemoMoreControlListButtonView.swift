//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreControlListButtonView<Icon: View>: View {

    @Injected(\.colors) var colors

    var centered: Bool = false
    var action: () -> Void
    var label: String
    var disabled: Bool = false
    var icon: () -> Icon

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
        .disabled(disabled)
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
