//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import struct StreamChatSwiftUI.ChatChannelView
import SwiftUI
import class StreamChat.ChatChannelController

struct AppControlsWithChat: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.chatViewModel) var chatViewModel

    private var canOpenChat: Bool

    private let size: CGFloat = 50
    private let cornerRadius: CGFloat = 24

    @ObservedObject var reactionsHelper = AppState.shared.reactionsHelper
    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel, canOpenChat: Bool = true) {
        self.viewModel = viewModel
        self.canOpenChat = canOpenChat
    }

    var body: some View {
        HStack(alignment: .center) {
            if let chatViewModel, chatViewModel.isChatEnabled {
                ChatIconView(viewModel: chatViewModel)
            }
            VideoIconView(viewModel: viewModel)
            MicrophoneIconView(viewModel: viewModel)
            ToggleCameraIconView(viewModel: viewModel)
            if !ProcessInfo.processInfo.isiOSAppOnMac {
                BroadcastIconView(
                    viewModel: viewModel,
                    preferredExtension: "io.getstream.iOS.VideoDemoApp.ScreenSharing"
                )
            }
            HangUpIconView(viewModel: viewModel)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .cornerRadius(
            cornerRadius,
            corners: [.topLeft, .topRight],
            backgroundColor: colors.callControlsBackground,
            extendToSafeArea: true
        )
        .onReceive(viewModel.$call) { reactionsHelper.call = $0 }
    }
}

struct ChatControlsHeader: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    @Injected(\.chatViewModel) var chatViewModel


    private let size: CGFloat = 50

    @ObservedObject var viewModel: CallViewModel

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        AppControlsWithChat(viewModel: viewModel, canOpenChat: false)
    }
}

struct ChatIconView: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: DemoChatViewModel
    let size: CGFloat

    init(viewModel: DemoChatViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }

    var body: some View {
        Button(
            action: {
                viewModel.isChatVisible.toggle()
            },
            label: {
                CallIconView(
                    icon: viewModel.isChatVisible ? .init(systemName: "message.fill") : .init(systemName: "message"),
                    size: size,
                    iconStyle: viewModel.isChatVisible ? .primary : .transparent
                ).overlay(
                    VStack {
                        HStack {
                            Spacer()
                            if viewModel.unreadCount > 0 {
                                Text("\(viewModel.unreadCount)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundColor(colors.text)
                                    .padding([.leading, .trailing], 4)
                                    .padding([.top, .bottom], 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .clipped()
                            }
                        }
                        Spacer()
                    }
                )
            }
        )
        .accessibility(identifier: "chatToggle")
    }
}

struct ChatView: View {

    var channelController: ChatChannelController
    var chatViewModel: DemoChatViewModel
    var callViewModel: CallViewModel

    var body: some View {
        NavigationView {
            ChatChannelView(
                viewFactory: DemoChatViewFactory.shared,
                channelController: channelController
            )
            .onAppear { chatViewModel.markAsRead() }
            .onDisappear { chatViewModel.channelDisappeared() }
            .navigationBarHidden(true)
        }
    }
}

extension View {

    @ViewBuilder
    func halfSheetIfAvailable<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        if #available(iOS 16.0, *) {
            sheet(isPresented: isPresented, onDismiss: onDismiss) {
                content()
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        } else {
            sheet(isPresented: isPresented, onDismiss: onDismiss) { content() }
        }
    }
}
