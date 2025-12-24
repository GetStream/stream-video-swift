//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoBroadcastMoreControlsListButtonView: View {
    @Injected(\.appearance) private var appearance

    @State private var selection: ScreensharingType = .inApp

    @ObservedObject var viewModel: CallViewModel
    let preferredExtension: String
    @StateObject private var broadcastObserver = BroadcastObserver()

    var body: some View {
        ZStack {
            if isCurrentUserScreenSharing {
                DemoMoreControlListButtonView(
                    action: { viewModel.stopScreensharing() },
                    label: selection == .inApp ? "Stop Screensharing" : "Stop Broadcasting"
                ) {
                    Image(systemName: "record.circle")
                        .foregroundColor(appearance.colors.accentRed)
                }
                .transition(.opacity.combined(with: .scale))
            } else {
                HStack(spacing: 12) {
                    inAppScreenshareButtonView

                    broadcastButtonView
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCurrentUserScreenSharing)
    }

    @ViewBuilder
    private var inAppScreenshareButtonView: some View {
        Menu {
            Button {
                viewModel.startScreensharing(type: .inApp, includeAudio: false)
                selection = .inApp
            } label: {
                Text("Without audio")
            }

            Button {
                viewModel.startScreensharing(type: .inApp, includeAudio: true)
                selection = .inApp
            } label: {
                Text("With audio")
            }

        } label: {
            DemoMoreControlListButtonView(
                action: {},
                label: "Screenshare"
            ) {
                Image(systemName: "record.circle")
                    .foregroundColor(appearance.colors.text)
            }
        }
    }

    @ViewBuilder
    private var broadcastButtonView: some View {
        ZStack {
            BroadcastPickerView(
                preferredExtension: preferredExtension,
                size: 44
            )
            .opacity(0.1)
            DemoMoreControlListButtonView(
                action: { /* No-op */ },
                label: "Broadcast"
            ) {
                Image(systemName: "record.circle")
                    .foregroundColor(appearance.colors.text)
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onChange(of: broadcastObserver.broadcastState, perform: { newValue in
            if newValue == .started {
                selection = .broadcast
                viewModel.startScreensharing(type: .broadcast)
            } else if newValue == .finished {
                viewModel.stopScreensharing()
                broadcastObserver.broadcastState = .notStarted
            }
        })
        .disabled(isBroadcastDisabled)
        .onAppear { broadcastObserver.observe() }
        .opacity(isBroadcastDisabled ? 0.75 : 1)
    }

    private var isCurrentUserScreenSharing: Bool {
        viewModel.call?.state.isCurrentUserScreensharing == true
    }

    private var isDisabled: Bool {
        guard viewModel.call?.state.screenSharingSession != nil else {
            return false
        }
        return viewModel.call?.state.isCurrentUserScreensharing == false
    }

    private var isInAppDisabled: Bool {
        isDisabled || (isCurrentUserScreenSharing && selection != .inApp)
    }

    private var isBroadcastDisabled: Bool {
        isDisabled || (isCurrentUserScreenSharing && selection != .broadcast)
    }
}
