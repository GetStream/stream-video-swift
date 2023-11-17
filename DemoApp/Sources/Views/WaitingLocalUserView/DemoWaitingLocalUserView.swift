//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoWaitingLocalUserView<Factory: DemoAppViewFactory>: View {

    @Injected(\.appearance) var appearance
    @Injected(\.chatViewModel) var chatViewModel

    @ObservedObject var viewModel: CallViewModel

    @State private var isSharePresented = false
    @State private var isChatVisible = false

    private let viewFactory: Factory

    internal init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            DefaultBackgroundGradient()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                VStack {
                    if let localParticipant = viewModel.localParticipant {
                        GeometryReader { proxy in
                            LocalVideoView(
                                viewFactory: viewFactory,
                                participant: localParticipant,
                                idSuffix: "waiting",
                                callSettings: viewModel.callSettings,
                                call: viewModel.call,
                                availableFrame: proxy.frame(in: .local)
                            )
                            .modifier(viewFactory.makeLocalParticipantViewModifier(
                                localParticipant: localParticipant,
                                callSettings: .init(get: { viewModel.callSettings }, set: { _ in }),
                                call: viewModel.call
                            ))
                        }
                    } else {
                        Spacer()
                    }

                    ZStack {
                        Color(appearance.colors.participantBackground)

                        VStack {
                            ZStack {
                                Circle()
                                    .fill(appearance.colors.lightGray)

                                Image(systemName: "person.fill.badge.plus")
                            }
                            .frame(maxHeight: 50)

                            Text("Share link to add participants")
                                .font(appearance.fonts.body.weight(.medium))

                            Button {
                                isSharePresented = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share")
                            }
                            .padding([.leading, .trailing])
                            .padding([.top, .bottom], 4)
                            .background(appearance.colors.primaryButtonBackground)
                            .clipShape(Capsule())
                            .sheet(isPresented: $isSharePresented) {
                                if let url = URL(string: callLink) {
                                    ShareActivityView(activityItems: [url])
                                } else {
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .cornerRadius(16)
                    .foregroundColor(Color.white)
                }
                .padding([.leading, .trailing], 8)

                viewFactory.makeCallControlsView(viewModel: viewModel)
                    .opacity(viewModel.callingState == .reconnecting ? 0 : 1)
            }
        }
        .chat(viewModel: viewModel, chatViewModel: chatViewModel)
    }

    private var callLink: String {
        AppEnvironment
            .baseURL
            .url
            .appendingPathComponent("video")
            .appendingPathComponent("demos")
            .addQueryParameter("id", value: callId)
            .addQueryParameter("type", value: callType)
            .absoluteString
    }

    private var callType: String {
        viewModel.call?.callType ?? .default
    }

    private var callId: String {
        viewModel.call?.callId ?? ""
    }
}
