//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
public struct CallParticipantsInfoView: View {
    
    private let padding: CGFloat = 16
    
    @StateObject var viewModel: CallParticipantsInfoViewModel
    @ObservedObject var callViewModel: CallViewModel
    var availableSize: CGSize
    
    public init(callViewModel: CallViewModel, availableSize: CGSize) {
        self.callViewModel = callViewModel
        self.availableSize = availableSize
        _viewModel = StateObject(
            wrappedValue: CallParticipantsInfoViewModel(
                call: callViewModel.call
            )
        )
    }
    
    public var body: some View {
        VStack {
            CallParticipantsView(
                viewModel: viewModel,
                callViewModel: callViewModel,
                maxHeight: availableSize.height - padding
            )
            .padding()
            .padding(.vertical, padding / 2)
            
            Spacer()
        }
    }
}

@available(iOS 14.0, *)
struct CallParticipantsView: View {
    
    @ObservedObject var viewModel: CallParticipantsInfoViewModel
    @ObservedObject var callViewModel: CallViewModel

    var maxHeight: CGFloat
        
    var body: some View {
        CallParticipantsViewContainer(
            viewModel: viewModel,
            participants: participants,
            call: callViewModel.call,
            blockedUsers: callViewModel.blockedUsers,
            callSettings: callViewModel.callSettings,
            maxHeight: maxHeight,
            inviteParticipantsShown: $viewModel.inviteParticipantsShown,
            inviteTapped: {
                viewModel.inviteParticipantsShown = true
            },
            muteTapped: {
                callViewModel.toggleMicrophoneEnabled()
            },
            closeTapped: {
                callViewModel.participantsShown = false
            }
        )
    }
    
    private var participants: [CallParticipant] {
        callViewModel.callParticipants
            .map(\.value)
            .sorted(by: { $0.name < $1.name })
    }
}

@available(iOS 14.0, *)
struct CallParticipantsViewContainer: View {
    
    @ObservedObject var viewModel: CallParticipantsInfoViewModel
    
    @Injected(\.colors) var colors
    @Injected(\.images) var images
        
    var participants: [CallParticipant]
    var call: Call?
    var blockedUsers: [User]
    var callSettings: CallSettings
    var maxHeight: CGFloat
    @Binding var inviteParticipantsShown: Bool
    var inviteTapped: () -> Void
    var muteTapped: () -> Void
    var closeTapped: () -> Void
    
    @State private var listHeight: CGFloat = 0
        
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    LazyVStack {
                        ForEach(participants) { participant in
                            CallParticipantView(
                                participant: participant,
                                menuActions: viewModel.menuActions(for: participant)
                            )
                            .id(participant.renderingId)
                        }
                        if !blockedUsers.isEmpty {
                            BlockedUsersView(
                                blockedUsers: blockedUsers,
                                unblockActions: viewModel.unblockActions(for:)
                            )
                        }
                    }
                    .padding()
                    .overlay(
                        GeometryReader { geo in
                            Color.clear.preference(key: HeightPreferenceKey.self, value: geo.size.height)
                        }
                    )
                    .onPreferenceChange(HeightPreferenceKey.self) { value in
                        if let value = value {
                            listHeight = value
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: listHeight)
                }
                
                HStack(spacing: 16) {
                    ParticipantsButton(title: L10n.Call.Participants.invite, onTapped: inviteTapped)
                    
                    ParticipantsButton(
                        title: callSettings.audioOn ? L10n.Call.Participants.muteme : L10n.Call.Participants.unmuteme,
                        primaryStyle: false,
                        onTapped: muteTapped
                    )
                }
                .padding()
                
                NavigationLink(isActive: $inviteParticipantsShown) {
                    InviteParticipantsView(
                        inviteParticipantsShown: $inviteParticipantsShown,
                        currentParticipants: participants,
                        call: call
                    )
                } label: {
                    EmptyView()
                }
            }
            .navigationTitle("\(L10n.Call.Participants.title) (\(participants.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        closeTapped()
                    } label: {
                        images.xmark
                            .foregroundColor(colors.tintColor)
                    }
                }
            })
        }
        .frame(height: inviteParticipantsShown ? maxHeight : popupHeight)
        .navigationViewStyle(.stack)
        .modifier(ShadowViewModifier())
    }
    
    private var popupHeight: CGFloat {
        // TODO: update this.
        let height = 44 + listHeight + 80
        if height > maxHeight {
            return maxHeight
        } else {
            return height
        }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat? = nil
    
    static func reduce(value: inout CGFloat?, nextValue: () -> CGFloat?) {
        value = value ?? nextValue()
    }
}

struct ParticipantsButton: View {
    
    @Injected(\.colors) private var colors
    @Injected(\.fonts) private var fonts
    
    private let cornerRadius: CGFloat = 24
    
    var title: String
    var primaryStyle: Bool = true
    var onTapped: () -> Void
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            Text(title)
                .font(fonts.headline)
                .bold()
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(
                    primaryStyle ? colors.textInverted : colors.secondaryButton
                )
                .background(primaryStyle ? colors.tintColor : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(primaryStyle ? colors.tintColor : colors.secondaryButton, lineWidth: 1)
                )
                .cornerRadius(cornerRadius)
        }
    }
}

struct BlockedUsersView: View {
    
    var blockedUsers: [User]
    var unblockActions: (User) -> [CallParticipantMenuAction]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(L10n.Call.Participants.blocked)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .padding(.vertical, 8)
                ForEach(blockedUsers) { blockedUser in
                    Text(blockedUser.id)
                        .contextMenu {
                            ForEach(unblockActions(blockedUser)) { menuAction in
                                Button {
                                    menuAction.action(blockedUser.id)
                                } label: {
                                    HStack {
                                        Image(systemName: menuAction.iconName)
                                        Text(menuAction.title)
                                        Spacer()
                                    }
                                }
                            }
                        }
                }
            }
            Spacer()
        }
    }
}

struct CallParticipantView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    
    private let imageSize: CGFloat = 48
    
    var participant: CallParticipant
    var menuActions: [CallParticipantMenuAction]
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                if #available(iOS 14.0, *) {
                    UserAvatar(imageURL: participant.profileImageURL, size: imageSize)
                        .overlay(
                            TopRightView {
                                OnlineIndicatorView(indicatorSize: imageSize * 0.3)
                            }
                        )
                }
                Text(participant.name)
                    .font(fonts.bodyBold)
                Spacer()
                (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                    .foregroundColor(participant.hasAudio ? colors.text : colors.accentRed)

                (participant.hasVideo ? images.videoTurnOn : images.videoTurnOff)
                    .foregroundColor(participant.hasVideo ? colors.text : colors.accentRed)
            }
            .padding(.all, 4)

            Divider()
        }
        .contextMenu {
            ForEach(menuActions) { menuAction in
                Button {
                    menuAction.action(participant.userId)
                } label: {
                    HStack {
                        Image(systemName: menuAction.iconName)
                        Text(menuAction.title)
                        Spacer()
                    }
                }
            }
        }
    }
}

extension CallParticipant {
    
    var renderingId: String {
        "\(trackLookupPrefix ?? id)-\(hasAudio)-\(shouldDisplayTrack)"
    }
}
