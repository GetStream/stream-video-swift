//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        VStack {
            Spacer()

            Group {
                VStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSharePromptVisible.toggle()
                        }
                    } label: {
                        HStack {
                            Text("Your Meeting is live!")

                            Spacer()

                            Text(
                                Image(
                                    systemName: isSharePromptVisible ? "chevron.down" : "chevron.up"
                                )
                            )
                        }
                        .foregroundColor(appearance.colors.text)
                        .font(appearance.fonts.title3.bold())
                    }

                    if isSharePromptVisible {
                        Group {
                            inviterOthersView
                            if !callId.isEmpty {
                                copyLinkView
                                qrCodeView
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .presentsMoreControls(viewModel: viewModel)
        .alignedToReadableContentGuide()
        .padding(.bottom)
    }

    private var callLink: String {
        AppEnvironment
            .baseURL
            .joinLink(callId, callType: callType)
            .absoluteString
    }

    private var callType: String {
        viewModel.call?.callType ?? .default
    }

    private var callId: String {
        viewModel.call?.callId ?? ""
    }

    @ViewBuilder
    private var inviterOthersView: some View {
        VStack {
            Text("Or share this call ID with the others you want in the meeting")
                .font(.body)
                .foregroundColor(Color(appearance.colors.textLowEmphasis))
                .frame(maxWidth: .infinity, alignment: .leading)

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
        }
    }

    @ViewBuilder
    private var copyLinkView: some View {
        VStack {
            Text("Share the link")
                .font(appearance.fonts.title3)
                .foregroundColor(appearance.colors.text)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Click the button below to copy the call link:")
                .multilineTextAlignment(.leading)
                .font(appearance.fonts.body)
                .foregroundColor(Color(appearance.colors.textLowEmphasis))

            Button {
                UIPasteboard.general.string = callLink
            } label: {
                HStack {
                    Label(
                        title: { Text("Copy invite link") },
                        icon: { Image(systemName: "doc.on.clipboard") }
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
        }
    }

    @ViewBuilder
    private var qrCodeView: some View {
        VStack {
            Text("Test on mobile")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(appearance.fonts.title3)
                .foregroundColor(appearance.colors.text)

            HStack {
                Text("To test on a mobile device, scan the QR Code:")
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity)
                    .font(appearance.fonts.body)
                    .foregroundColor(Color(appearance.colors.textLowEmphasis))

                QRCodeView(text: callLink)
                    .frame(width: 100, height: 100, alignment: .center)
            }
        }
    }
}
