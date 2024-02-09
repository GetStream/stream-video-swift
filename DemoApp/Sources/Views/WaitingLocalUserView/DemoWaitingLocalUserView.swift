//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoWaitingLocalUserView<Factory: DemoAppViewFactory>: View {

    @Injected(\.appearance) var appearance
    @Injected(\.chatViewModel) var chatViewModel

    @ObservedObject var viewModel: CallViewModel

    @State private var isSharePresented = false
    @State private var isChatVisible = false
    @State private var isSharePromptVisible = true
    @State private var isInviteViewVisible = false

    private let viewFactory: Factory

    internal init(
        viewFactory: Factory,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            viewFactory.makeCallTopView(viewModel: viewModel)

            Group {
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
                    .overlay(sharePromptView)
                } else {
                    Spacer()
                }
            }
            .padding(.horizontal)

            viewFactory.makeCallControlsView(viewModel: viewModel)
        }
        .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
        .chat(viewModel: viewModel, chatViewModel: chatViewModel)
        .background(Color(appearance.colors.callBackground).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var sharePromptView: some View {
        if isSharePromptVisible {
            VStack {
                Spacer()

                Group {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Your Meeting is live!")

                            Spacer()

                            Button {
                                isSharePromptVisible = false
                            } label: {
                                Text(Image(systemName: "xmark"))
                            }
                        }
                        .foregroundColor(appearance.colors.text)
                        .font(appearance.fonts.title3.bold())

                        Button {
                            isInviteViewVisible = true
                        } label: {
                            HStack {
                                Label(
                                    title: { Text("Add Others") },
                                    icon: { Image(systemName: "person.fill.badge.plus") }
                                )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal)
                        }
                        .frame(height: 40)
                        .buttonStyle(.plain)
                        .foregroundColor(appearance.colors.text)
                        .background(appearance.colors.accentBlue)
                        .clipShape(Capsule())
                        .frame(maxWidth: .infinity)

                        Text("Or share this call ID with the others you want in the meeting")
                            .font(.body)
                            .foregroundColor(Color(appearance.colors.textLowEmphasis))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if !callId.isEmpty {
                            HStack {
                                Text("Call ID:")
                                    .foregroundColor(Color(appearance.colors.textLowEmphasis))

                                Button {
                                    UIPasteboard.general.string = callLink
                                } label: {
                                    HStack {

                                        Text("\(callId)")
                                            .foregroundColor(appearance.colors.onlineIndicatorColor)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.5)

                                        Text(Image(systemName: "doc.on.clipboard"))
                                            .foregroundColor(Color(appearance.colors.textLowEmphasis))

                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .font(.body)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .background(Color(appearance.colors.participantBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .sheet(isPresented: $isInviteViewVisible) {
                    NavigationView {
                        InviteParticipantsView(
                            inviteParticipantsShown: $isInviteViewVisible,
                            currentParticipants: viewModel.participants,
                            call: viewModel.call
                        )
                    }
                    .navigationViewStyle(.stack)
                }
            }
            .alignedToReadableContentGuide()
            .padding(.bottom)
        } else {
            EmptyView()
        }
    }

    private var callLink: String {
        AppEnvironment
            .baseURL
            .url
            .appendingPathComponent("join")
            .appendingPathComponent(callId)
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
