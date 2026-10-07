//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallTopView<Factory: ViewFactory>: View {

    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.layout) private var layout

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
                HStack(spacing: layout.spacingXs) {
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
                HStack(alignment: .center, spacing: layout.spacingXs) {
                    DemoCallDurationView(
                        viewModel: viewModel,
                        isEncrypted: isEncrypted
                    )
                }
                .frame(height: 44)
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: layout.spacingXs) {
                Spacer()
                livestreamControlsView
                HangUpIconView(viewModel: viewModel)
            }
            .frame(maxWidth: .infinity)
        }
        .overlay(overlayView)
        .padding(.horizontal, layout.spacingMd)
        .padding(.top, layout.spacingMd)
        .frame(maxWidth: .infinity)
    }

    private var isCallLivestream: Bool {
        guard let call = viewModel.call else { return false }
        return call.callType == .livestream
    }

    private var isEncrypted: Bool {
        viewModel.call?.state.settings?.encryption.mode == .autoOn
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
                                .foregroundColor(Color(colors.accentSuccess))
                        }
                    } else {
                        Label {
                            Text("Stop Live")
                        } icon: {
                            Image(systemName: "stop.fill")
                                .foregroundColor(Color(colors.accentError))
                        }
                    }
                }

            } label: {
                CallIconView(
                    icon: images.settings,
                    size: 44,
                    iconStyle: .secondary
                )
            }
        } else {
            EmptyView()
        }
    }
}

private struct DemoCallDurationView: View {
    @Injected(\.formatters.mediaDuration) private var formatter
    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    @ObservedObject var viewModel: CallViewModel
    var isEncrypted: Bool

    @State private var duration: TimeInterval

    init(viewModel: CallViewModel, isEncrypted: Bool) {
        self.viewModel = viewModel
        self.isEncrypted = isEncrypted
        _duration = .init(
            initialValue: viewModel.call?.state.duration ?? 0
        )
    }

    var body: some View {
        Group {
            switch viewModel.callingState {
            case .outgoing:
                CallDurationView(viewModel)
            case .inCall:
                inCallChip
            default:
                EmptyView()
            }
        }
        .onReceive(viewModel.call?.state.$duration) { duration = $0 }
    }

    @ViewBuilder
    private var inCallChip: some View {
        if duration > 0, let formatted = formatter.format(duration) {
            HStack(spacing: layout.spacingXxs) {
                if isEncrypted {
                    Image(systemName: lockSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12)
                        .foregroundColor(Color(colors.accentSuccess))
                        .accessibility(identifier: "e2eeEncryptedBadge")
                }
                if viewModel.recordingState == .recording {
                    images.recordIcon
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12)
                        .foregroundColor(Color(colors.accentError))
                }
                Text(formatted)
                    .font(fonts.bodyBold.monospacedDigit())
                    .foregroundColor(Color(colors.textPrimary))
                    .minimumScaleFactor(0.2)
                    .lineLimit(1)
                    .layoutPriority(2)
            }
            .padding(.horizontal, layout.spacingMd)
            .padding(.vertical, layout.spacingXxs)
            .background(Color(colors.backgroundCoreSurfaceDefault))
            .clipShape(Capsule())
            .accessibility(
                identifier: viewModel.recordingState == .recording
                    ? "recordingView"
                    : "callDurationView"
            )
        }
    }

    private var lockSymbol: String {
        if #available(iOS 16.0, *) {
            return "lock.shield"
        }
        return "lock.fill"
    }
}

struct SharingIndicator: View {

    @Injected(\.colors) private var colors
    @Injected(\.images) private var images
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

    @ObservedObject var viewModel: CallViewModel
    @Binding var sharingPopupDismissed: Bool

    init(viewModel: CallViewModel, sharingPopupDismissed: Binding<Bool>) {
        _viewModel = ObservedObject(initialValue: viewModel)
        _sharingPopupDismissed = sharingPopupDismissed
    }

    var body: some View {
        HStack(spacing: layout.spacingXs) {
            Text("You are sharing your screen")
                .font(fonts.headline)
                .foregroundColor(Color(colors.textPrimary))
            Divider()
            Button {
                viewModel.stopScreensharing()
            } label: {
                Text("Stop sharing")
                    .font(fonts.headline)
                    .foregroundColor(Color(colors.accentPrimary))
            }
            Button {
                sharingPopupDismissed = true
            } label: {
                images.xmark
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 14)
                    .foregroundColor(Color(colors.accentPrimary))
            }
            .padding(.leading, layout.spacingXxs)
        }
        .padding(.all, layout.spacingXs)
        .modifier(ShadowViewModifier())
    }
}

/// Modifier for adding shadow and corner radius to a view.
private struct ShadowViewModifier: ViewModifier {

    @Injected(\.colors) private var colors
    @Injected(\.layout) private var layout

    func body(content: Content) -> some View {
        content
            .background(Color(colors.backgroundCoreElevation1))
            .cornerRadius(layout.radiusXl)
            .modifier(ShadowModifier())
            .overlay(
                RoundedRectangle(cornerRadius: layout.radiusXl)
                    .stroke(
                        Color(colors.borderCoreDefault),
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
