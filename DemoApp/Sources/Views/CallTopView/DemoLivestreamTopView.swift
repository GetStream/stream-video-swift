//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoLivestreamTopView: View {

    @Injected(\.fonts) var fonts
    @Injected(\.colors) var colors
    @Injected(\.images) var images

    var viewModel: CallViewModel

    @State var sharingPopupDismissed = false

    @State var backstage: Bool
    var backstagePublisher: AnyPublisher<Bool, Never>?

    @State var currentUserCanStartBroadcastCall: Bool
    var currentUserCanStartBroadcastCallPublisher: AnyPublisher<Bool, Never>?

    @State var isCurrentUserScreensharing: Bool
    var isCurrentUserScreensharingPublisher: AnyPublisher<Bool, Never>?

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel

        backstage = viewModel.call?.state.backstage ?? false
        backstagePublisher = viewModel
            .call?
            .state
            .$backstage
            .removeDuplicates()
            .eraseToAnyPublisher()

        currentUserCanStartBroadcastCall = viewModel
            .call?
            .currentUserHasCapability(.startBroadcastCall) ?? false
        currentUserCanStartBroadcastCallPublisher = viewModel
            .call?
            .state
            .$ownCapabilities
            .compactMap { $0.contains(.startBroadcastCall) }
            .removeDuplicates()
            .eraseToAnyPublisher()

        isCurrentUserScreensharing = viewModel
            .call?
            .state
            .isCurrentUserScreensharing ?? false
        isCurrentUserScreensharingPublisher = viewModel
            .call?
            .state
            .$isCurrentUserScreensharing
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            livestreamControlsView
            HangUpIconView(viewModel: viewModel)
        }
        .padding(.horizontal, 16)
        .padding(.top)
        .frame(maxWidth: .infinity)
        .overlay(overlayView)
        .onReceive(backstagePublisher) { backstage = $0 }
        .onReceive(currentUserCanStartBroadcastCallPublisher) { currentUserCanStartBroadcastCall = $0 }
        .onReceive(isCurrentUserScreensharingPublisher) { isCurrentUserScreensharing = $0 }
    }

    @ViewBuilder
    var livestreamControlsView: some View {
        if currentUserCanStartBroadcastCall {
            Menu {
                Button {
                    Task {
                        do {
                            if backstage {
                                try await viewModel.call?.goLive()
                            } else {
                                try await viewModel.call?.stopLive()
                            }
                        } catch {
                            log.error(error)
                        }
                    }
                } label: {
                    if backstage {
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

    @ViewBuilder
    private var overlayView: some View {
        if isCurrentUserScreensharing {
            SharingIndicator(
                viewModel: viewModel,
                sharingPopupDismissed: $sharingPopupDismissed
            )
        }
    }
}
