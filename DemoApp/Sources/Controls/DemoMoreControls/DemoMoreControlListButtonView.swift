//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoMoreControlListButtonView<Icon: View>: View {

    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    var centered: Bool = false
    var primaryStyle: Bool = false
    var action: () -> Void
    var label: String
    var disabled: Bool = false
    var icon: () -> Icon

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: layout.spacingSm) {
                Label(
                    title: {
                        Text(label)
                            .font(primaryStyle ? fonts.bodyBold : fonts.body)
                    },
                    icon: { icon() }
                )

                if !centered {
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, layout.spacingSm)
        }
        .frame(minHeight: layout.buttonVisualHeightLg)
        .buttonStyle(.borderless)
        .foregroundColor(
            primaryStyle
                ? Color(colors.buttonPrimaryTextOnAccent)
                : Color(colors.textPrimary)
        )
        .background(
            primaryStyle
                ? Color(colors.buttonPrimaryBackground)
                : Color(colors.backgroundCoreElevation1)
        )
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
            primaryStyle: true,
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
