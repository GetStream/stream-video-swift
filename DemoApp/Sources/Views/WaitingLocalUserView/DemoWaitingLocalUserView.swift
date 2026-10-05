//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoWaitingLocalUserView<Factory: DemoAppViewFactory>: View {

    @Injected(\.chatViewModel) var chatViewModel
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    @Injected(\.layout) private var layout

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
        VStack(spacing: layout.spacingXs) {
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
            .padding(.horizontal, layout.spacingMd)

            viewFactory.makeCallControlsView(viewModel: viewModel)
        }
        .presentParticipantListView(viewModel: viewModel, viewFactory: viewFactory)
        .chat(viewModel: viewModel, chatViewModel: chatViewModel)
        .background(Color(colors.backgroundCoreApp).edgesIgnoringSafeArea(.all))
    }

    @ViewBuilder
    private var sharePromptView: some View {
        VStack(spacing: 0) {
            Spacer()

            Group {
                VStack(spacing: layout.spacingMd) {
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isSharePromptVisible.toggle()
                        }
                    } label: {
                        HStack(spacing: layout.spacingXs) {
                            Text("Your Meeting is live!")

                            Spacer()

                            Text(
                                Image(
                                    systemName: isSharePromptVisible ? "chevron.down" : "chevron.up"
                                )
                            )
                        }
                        .foregroundColor(Color(colors.textPrimary))
                        .font(fonts.title3.bold())
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
                .padding(layout.spacingMd)
            }
            .background(Color(colors.backgroundCoreElevation1))
            .clipShape(RoundedRectangle(cornerRadius: layout.radiusXl))
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
        .padding(.horizontal, layout.spacingXs)
        .padding(.bottom, layout.spacing3xl)
    }

    private var callLink: String {
        AppEnvironment.EncryptionKeys.shared
            .inviteURL(callId: callId, callType: callType)
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
        VStack(spacing: layout.spacingXs) {
            Button {
                isInviteViewVisible = true
            } label: {
                HStack(spacing: layout.spacingXs) {
                    Label(
                        title: { Text("Add Others").font(fonts.bodyBold) },
                        icon: { Image(systemName: "person.fill.badge.plus") }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, layout.spacingMd)
            }
            .frame(height: layout.buttonVisualHeightLg)
            .buttonStyle(.plain)
            .foregroundColor(Color(colors.buttonPrimaryTextOnAccent))
            .background(Color(colors.buttonPrimaryBackground))
            .clipShape(Capsule())
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var copyLinkView: some View {
        VStack(spacing: layout.spacingXs) {
            Button {
                UIPasteboard.general.string = callLink
            } label: {
                HStack(spacing: layout.spacingXs) {
                    Label(
                        title: {
                            Text("Call id: \(Text(callId).font(fonts.caption1).fontWeight(.medium))").lineLimit(1)
                                .minimumScaleFactor(0.7)
                        },
                        icon: { Image(systemName: "doc.on.clipboard") }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, layout.spacingMd)
            }
            .frame(height: layout.buttonVisualHeightLg)
            .buttonStyle(.plain)
            .foregroundColor(Color(colors.buttonSecondaryText))
            .background(Color(colors.buttonSecondaryBackground))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(colors.buttonSecondaryBorder), lineWidth: 1))
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var qrCodeView: some View {
        VStack(spacing: layout.spacingXs) {
            Group {
                QRCodeView(text: callLink)
                    .frame(width: 100, height: 100, alignment: .center)
                    .padding(layout.spacingMd)
            }
            .frame(maxWidth: .infinity)
            .background(Color(colors.backgroundCoreOnElevation))
            .clipShape(RoundedRectangle(cornerRadius: layout.radiusXl))

            Text("Scan the QR code to join from another device.")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(fonts.body)
                .foregroundColor(Color(colors.textPrimary))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }
}
