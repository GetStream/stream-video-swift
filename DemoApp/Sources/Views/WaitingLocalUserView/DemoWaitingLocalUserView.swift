//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoWaitingLocalUserView<Factory: DemoAppViewFactory>: View {

    @Injected(\.videoAppearance) private var videoAppearance
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
            .padding(.horizontal, tokens.layout.spacingMd)

            viewFactory.makeCallControlsView(viewModel: viewModel)
        }
        .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
        .chat(viewModel: viewModel, chatViewModel: chatViewModel)
        .background(Color(tokens.colors.backgroundCoreApp).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var sharePromptView: some View {
        VStack {
            Spacer()

            Group {
                VStack(spacing: tokens.layout.spacingMd) {
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
                        .foregroundColor(Color(tokens.colors.textPrimary))
                        .font(tokens.fonts.title3.bold())
                    }

                    if isSharePromptVisible {
                        Group {
                            inviteOthersView
                            if !callId.isEmpty {
                                copyLinkView
                                qrCodeView
                            }
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(tokens.layout.spacingMd)
            }
            .background(Color(tokens.colors.backgroundCoreElevation1))
            .clipShape(RoundedRectangle(cornerRadius: tokens.layout.radiusXl))
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
        .padding(.horizontal, tokens.layout.spacingXs)
        .padding(.bottom, tokens.layout.spacing3xl)
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
    private var inviteOthersView: some View {
        VStack {
            Button {
                isInviteViewVisible = true
            } label: {
                HStack {
                    Label(
                        title: { Text("Add Others").font(tokens.fonts.bodyBold) },
                        icon: { Image(systemName: "person.fill.badge.plus") }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, tokens.layout.spacingMd)
            }
            .frame(height: tokens.layout.buttonVisualHeightLg)
            .buttonStyle(.plain)
            .foregroundColor(Color(tokens.colors.buttonPrimaryTextOnAccent))
            .background(Color(tokens.colors.buttonPrimaryBackground))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var copyLinkView: some View {
        VStack {
            Button {
                UIPasteboard.general.string = callLink
            } label: {
                HStack {
                    Label(
                        title: {
                            Text("Call id: \(Text(callId).font(tokens.fonts.caption1).fontWeight(.medium))").lineLimit(1)
                                .minimumScaleFactor(0.7)
                        },
                        icon: { Image(systemName: "doc.on.clipboard") }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, tokens.layout.spacingMd)
            }
            .frame(height: tokens.layout.buttonVisualHeightLg)
            .buttonStyle(.plain)
            .foregroundColor(Color(tokens.colors.buttonSecondaryText))
            .background(Color(tokens.colors.buttonSecondaryBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(tokens.colors.buttonSecondaryBorder), lineWidth: 1))
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var qrCodeView: some View {
        VStack {
            Group {
                QRCodeView(text: callLink)
                    .frame(width: 100, height: 100, alignment: .center)
                    .padding(tokens.layout.spacingMd)
            }
            .frame(maxWidth: .infinity)
            .background(Color(tokens.colors.backgroundCoreOnElevation))
            .clipShape(RoundedRectangle(cornerRadius: tokens.layout.radiusXl))

            Text("Scan the QR code to join from another device.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(tokens.fonts.body)
                .foregroundColor(Color(tokens.colors.textPrimary))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
