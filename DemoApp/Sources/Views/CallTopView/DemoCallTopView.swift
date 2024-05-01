//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallTopView: View {

    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images

    @ObservedObject private var reactionsAdapter = InjectedValues[\.reactionsAdapter]

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var appState = AppState.shared
    @State var sharingPopupDismissed = false

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack {
                if viewModel.callParticipants.count > 1, !hideLayoutMenu {
                    LayoutMenuView(viewModel: viewModel)
                        .accessibility(identifier: "viewMenu")
                }

                ToggleCameraIconView(viewModel: viewModel)

                Spacer()
            }
            .frame(maxWidth: .infinity)

            HStack(alignment: .center) {
                CallDurationView(viewModel)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                HangUpIconView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.top)
        .frame(maxWidth: .infinity)
        .overlay(
            viewModel.call?.state.isCurrentUserScreensharing == true ?
                SharingIndicator(
                    viewModel: viewModel,
                    sharingPopupDismissed: $sharingPopupDismissed
                )
                .opacity(sharingPopupDismissed ? 0 : 1)
                : nil
        )
    }

    private var hideLayoutMenu: Bool {
        viewModel.call?.state.screenSharingSession != nil
            && viewModel.call?.state.isCurrentUserScreensharing == false
    }

    @ViewBuilder
    private func reactionsList() -> some View {
        ForEach(availableReactions) { reaction in
            Button {
                reactionsAdapter.send(reaction: reaction.id == .lowerHand ? .raiseHand : reaction)
            } label: {
                Label(
                    title: {
                        Text(reaction.title)
                    },
                    icon: { Image(systemName: reaction.iconName) }
                )
            }
        }
    }

    private var availableReactions: [Reaction] {
        guard let userId = viewModel.localParticipant?.userId else {
            return []
        }

        let hasRaisedHand = reactionsAdapter.activeReactions[userId]?.first(where: { $0.id == .raiseHand }) != nil

        if hasRaisedHand {
            return reactionsAdapter.availableReactions.filter { $0.id != .raiseHand }
        } else {
            return reactionsAdapter.availableReactions.filter { $0.id != .lowerHand }
        }
    }
}

struct SharingIndicator: View {

    @ObservedObject var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool

    init(viewModel: CallViewModel, sharingPopupDismissed: Binding<Bool>) {
        _viewModel = ObservedObject(initialValue: viewModel)
        _sharingPopupDismissed = sharingPopupDismissed
    }

    var body: some View {
        HStack {
            Text("You are sharing your screen")
                .font(.headline)
            Divider()
            Button {
                viewModel.stopScreensharing()
            } label: {
                Text("Stop sharing")
                    .font(.headline)
            }
            Button {
                sharingPopupDismissed = true
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
            }
            .padding(.leading, 4)
        }
        .padding(.all, 8)
        .modifier(ShadowViewModifier())
    }
}

/// Modifier for adding shadow and corner radius to a view.
private struct ShadowViewModifier: ViewModifier {

    var cornerRadius: CGFloat = 16
    var borderColor: Color = Color.gray

    func body(content: Content) -> some View {
        content
            .background(Color(UIColor.systemBackground))
            .cornerRadius(cornerRadius)
            .modifier(ShadowModifier())
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        borderColor,
                        lineWidth: 0.5
                    )
            )
    }
}

/// Modifier for adding shadow to a view.
private struct ShadowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 12)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}
