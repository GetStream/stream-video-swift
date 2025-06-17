//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct BroadcastIconView: View {

    var viewModel: CallViewModel
    var preferredExtension: String
    var size: CGFloat
    var iconStyle = CallIconStyle.transparent
    var iconSize: CGFloat = 44
    var offset: CGPoint

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
        if #available(iOS 14.0, *) {
            ContentView(
                viewModel: viewModel,
                size: size,
                preferredExtension: preferredExtension,
                iconSize: iconSize,
                offset: offset,
                screenSharingSession: viewModel.call?.state.screenSharingSession,
                isCurrentUserScreensharing: viewModel.call?.state.isCurrentUserScreensharing ?? false
            )
        } else {
            ContentView_iOS13(
                viewModel: viewModel,
                size: size,
                preferredExtension: preferredExtension,
                iconSize: iconSize,
                offset: offset,
                screenSharingSession: viewModel.call?.state.screenSharingSession,
                isCurrentUserScreensharing: viewModel.call?.state.isCurrentUserScreensharing ?? false
            )
        }
    }
}

extension BroadcastIconView {

    @available(iOS 14.0, *)
    struct ContentView: View {
        @Injected(\.images) var images
        @Injected(\.colors) var colors

        var viewModel: CallViewModel
        let size: CGFloat
        let preferredExtension: String
        let iconStyle = CallIconStyle.transparent
        let iconSize: CGFloat
        let offset: CGPoint

        @StateObject var broadcastObserver = BroadcastObserver()
        @State var screenSharingSession: ScreenSharingSession?
        @State var isCurrentUserScreensharing: Bool

        var body: some View {
            ZStack(alignment: .center) {
                backgroundView
                content
            }
            .frame(width: size, height: size)
            .modifier(ShadowModifier())
            .disabled(isDisabled)
            .onAppear { broadcastObserver.observe() }
            .onChange(of: broadcastObserver.broadcastState) { newValue in
                if newValue == .started {
                    viewModel.startScreensharing(type: .broadcast)
                } else if newValue == .finished {
                    viewModel.stopScreensharing()
                    broadcastObserver.broadcastState = .notStarted
                }
            }
            .onReceive(viewModel.call?.state.$screenSharingSession) { screenSharingSession = $0 }
            .onReceive(viewModel.call?.state.$isCurrentUserScreensharing.removeDuplicates()) { isCurrentUserScreensharing = $0 }
            .debugViewRendering()
        }

        @ViewBuilder
        private var backgroundView: some View {
            Circle()
                .fill(iconStyle.backgroundColor.opacity(iconStyle.opacity))
        }

        @ViewBuilder
        private var content: some View {
            BroadcastPickerView(
                preferredExtension: preferredExtension,
                size: iconSize
            )
            .frame(width: iconSize, height: iconSize)
            .offset(x: offset.x, y: offset.y)
            .foregroundColor(iconStyle.foregroundColor)
        }

        private var isDisabled: Bool {
            guard screenSharingSession != nil else {
                return false
            }
            return isCurrentUserScreensharing == false
        }
    }

    @available(iOS, introduced: 13, obsoleted: 14)
    struct ContentView_iOS13: View {
        @Injected(\.images) var images
        @Injected(\.colors) var colors

        var viewModel: CallViewModel
        let size: CGFloat
        let preferredExtension: String
        let iconStyle = CallIconStyle.transparent
        let iconSize: CGFloat
        let offset: CGPoint

        @BackportStateObject var broadcastObserver = BroadcastObserver()
        @State var screenSharingSession: ScreenSharingSession?
        @State var isCurrentUserScreensharing: Bool

        var body: some View {
            ZStack(alignment: .center) {
                backgroundView
                content
            }
            .frame(width: size, height: size)
            .modifier(ShadowModifier())
            .disabled(isDisabled)
            .onAppear { broadcastObserver.observe() }
            .onChange(of: broadcastObserver.broadcastState) { newValue in
                if newValue == .started {
                    viewModel.startScreensharing(type: .broadcast)
                } else if newValue == .finished {
                    viewModel.stopScreensharing()
                    broadcastObserver.broadcastState = .notStarted
                }
            }
            .onReceive(viewModel.call?.state.$screenSharingSession) { screenSharingSession = $0 }
            .onReceive(viewModel.call?.state.$isCurrentUserScreensharing.removeDuplicates()) { isCurrentUserScreensharing = $0 }
        }

        @ViewBuilder
        private var backgroundView: some View {
            Circle()
                .fill(iconStyle.backgroundColor.opacity(iconStyle.opacity))
        }

        @ViewBuilder
        private var content: some View {
            BroadcastPickerView(
                preferredExtension: preferredExtension,
                size: iconSize
            )
            .frame(width: iconSize, height: iconSize)
            .offset(x: offset.x, y: offset.y)
            .foregroundColor(iconStyle.foregroundColor)
        }

        private var isDisabled: Bool {
            guard screenSharingSession != nil else {
                return false
            }
            return isCurrentUserScreensharing == false
        }
    }
}
