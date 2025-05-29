//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI
import Combine

public struct ScreenshareIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        PublisherSubscriptionView(
            initial: viewModel.call?.state.isCurrentUserScreensharing ?? false,
            publisher: viewModel.call?.state.$isCurrentUserScreensharing.eraseToAnyPublisher()
        ) { isCurrentUserScreensharing in
            Button {
                viewModel.startScreensharing(type: .inApp)
            } label: {
                CallIconView(
                    icon: images.screenshareIcon,
                    size: size,
                    iconStyle: (isCurrentUserScreensharing ?.primary : .transparent)
                )
            }
        }
    }
}

@available(iOS 14.0, *)
public struct BroadcastIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    var viewModel: CallViewModel
    @StateObject var broadcastObserver = BroadcastObserver()
    let size: CGFloat
    let iconStyle = CallIconStyle.transparent
    let preferredExtension: String
    let iconSize: CGFloat = 44
    let offset: CGPoint

    public init(
        viewModel: CallViewModel,
        preferredExtension: String,
        size: CGFloat = 44
    ) {
        self.viewModel = viewModel
        self.preferredExtension = preferredExtension
        self.size = size
        offset = {
            if #available(iOS 16.0, *) {
                return .init(x: -5, y: -4)
            } else {
                return .zero
            }
        }()
    }
    
    public var body: some View {
        withDisableControl {
            ZStack(alignment: .center) {
                Circle().fill(
                    iconStyle.backgroundColor.opacity(iconStyle.opacity)
                )
                BroadcastPickerView(
                    preferredExtension: preferredExtension,
                    size: iconSize
                )
                .frame(width: iconSize, height: iconSize)
                .offset(x: offset.x, y: offset.y)
                .foregroundColor(iconStyle.foregroundColor)
            }
            .frame(width: size, height: size)
            .modifier(ShadowModifier())
            .onChange(of: broadcastObserver.broadcastState, perform: { newValue in
                if newValue == .started {
                    viewModel.startScreensharing(type: .broadcast)
                } else if newValue == .finished {
                    viewModel.stopScreensharing()
                    broadcastObserver.broadcastState = .notStarted
                }
            })
            .onAppear {
                broadcastObserver.observe()
            }
        }
    }

    @ViewBuilder
    private func withDisableControl(_ content: @escaping () -> some View) -> some View {
        let initial = {
            guard viewModel.call?.state.screenSharingSession != nil else {
                return false
            }
            return viewModel.call?.state.isCurrentUserScreensharing == false
        }()

        PublisherSubscriptionView(
            initial: initial,
            publisher: Publishers.combineLatest(
                viewModel.call?.state.$screenSharingSession.eraseToAnyPublisher(),
                viewModel.call?.state.$isCurrentUserScreensharing.eraseToAnyPublisher()
            )
            .map { screenSharingSession, isCurrentUserScreensharing in
                guard screenSharingSession != nil else {
                    return false
                }
                return isCurrentUserScreensharing == false
            }
                .eraseToAnyPublisher()
        ) { isDisabled in
            content().disabled(isDisabled)
        }
    }
}
