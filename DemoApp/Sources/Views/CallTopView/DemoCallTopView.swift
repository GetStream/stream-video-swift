//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallTopView<Factory: ViewFactory>: View {

    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images

    private var viewFactory: Factory

    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var appState = AppState.shared
    @State var sharingPopupDismissed = false

    init(
        viewFactory: Factory = DefaultViewFactory.shared,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    var body: some View {
        HStack(spacing: 0) {
            if !isCallLivestream {
                HStack {
                    if viewModel.callParticipants.count > 1, !hideLayoutMenu {
                        LayoutMenuView(viewModel: viewModel)
                            .accessibility(identifier: "viewMenu")
                    }

                    ToggleCameraIconView(viewModel: viewModel)

                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }

            if !isCallLivestream {
                HStack(alignment: .center) {
                    CallDurationView(viewModel)
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)
            }

            HStack {
                Spacer()
                livestreamControlsView
                HangUpIconView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(overlayView)
        .padding(.horizontal, 16)
        .padding(.top)
        .frame(maxWidth: .infinity)
    }

    private var isCallLivestream: Bool {
        guard let call = viewModel.call else { return false }
        return call.callType == .livestream
    }

    private var hideLayoutMenu: Bool {
        viewModel.call?.state.screenSharingSession != nil
            && viewModel.call?.state.isCurrentUserScreensharing == false
    }

    @ViewBuilder
    private var overlayView: some View {
        if viewModel.call?.state.isCurrentUserScreensharing == true, !sharingPopupDismissed {
            SharingIndicator(
                viewModel: viewModel,
                sharingPopupDismissed: $sharingPopupDismissed
            )
        } else {
            if let call = viewModel.call {
                if call.callType == .livestream, call.currentUserHasCapability(.startBroadcastCall) {
                    viewFactory.makePermissionsPromptView(call: call)
                } else if call.callType != .livestream {
                    viewFactory.makePermissionsPromptView(call: call)
                } else {
                    EmptyView()
                }
            }
        }
    }

    @ViewBuilder
    private var livestreamControlsView: some View {
        if let call = viewModel.call, call.callType == .livestream, call.currentUserHasCapability(.startBroadcastCall) {
            Menu {
                Button {
                    Task {
                        do {
                            if call.state.backstage {
                                try await call.goLive()
                            } else {
                                try await call.stopLive()
                            }
                        } catch {
                            log.error(error)
                        }
                    }
                } label: {
                    if call.state.backstage {
                        Label {
                            Text("Start Live")
                        } icon: {
                            Image(systemName: "play.fill")
                                .foregroundColor(colors.accentGreen)
                        }
                    } else {
                        Label {
                            Text("Stop Live")
                        } icon: {
                            Image(systemName: "stop.fill")
                                .foregroundColor(colors.accentRed)
                        }
                    }
                }

            } label: {
                CallIconView(
                    icon: Image(systemName: "gear"),
                    size: 44,
                    iconStyle: .transparent
                )
            }
        } else {
            EmptyView()
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
