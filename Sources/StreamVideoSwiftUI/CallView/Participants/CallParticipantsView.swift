//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import SwiftUI

@available(iOS 14.0, *)
struct CallParticipantsView: View {
    
    @ObservedObject var viewModel: CallViewModel

    var maxHeight: CGFloat
        
    var body: some View {
        CallParticipantsViewContainer(
            participants: participants,
            callSettings: viewModel.callSettings,
            maxHeight: maxHeight,
            inviteParticipantsShown: $viewModel.inviteParticipantsShown,
            inviteTapped: {
                viewModel.inviteParticipantsShown = true
            },
            muteTapped: {
                viewModel.toggleMicrophoneEnabled()
            },
            closeTapped: {
                viewModel.participantsShown = false
            }
        )
    }
    
    private var participants: [CallParticipant] {
        viewModel.callParticipants
            .map(\.value)
            .sorted(by: { $0.name < $1.name })
    }
}

@available(iOS 14.0, *)
struct CallParticipantsViewContainer: View {
    
    @Injected(\.colors) var colors
    @Injected(\.images) var images
        
    var participants: [CallParticipant]
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
                            CallParticipantView(participant: participant)
                                .id(participant.renderingId)
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
                        title: callSettings.audioOn ? L10n.Call.Participants.unmuteme : L10n.Call.Participants.muteme,
                        primaryStyle: false,
                        onTapped: muteTapped
                    )
                }
                .padding()
                
                NavigationLink(isActive: $inviteParticipantsShown) {
                    InviteParticipantsView(
                        inviteParticipantsShown: $inviteParticipantsShown,
                        currentParticipants: participants
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

struct CallParticipantView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.fonts) var fonts
    @Injected(\.images) var images
    
    private let imageSize: CGFloat = 48
    
    var participant: CallParticipant
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                if #available(iOS 14.0, *) {
                    LazyImage(url: participant.profileImageURL)
                        .frame(width: imageSize, height: imageSize)
                        .clipShape(Circle())
                        .overlay(
                            participant.isOnline ?
                                TopRightView {
                                    OnlineIndicatorView(indicatorSize: imageSize * 0.3)
                                }
                                .offset(x: 3, y: -1)
                                : nil
                        )
                }
                Text(participant.name)
                    .font(fonts.bodyBold)
                Spacer()
                if participant.isOnline {
                    (participant.hasAudio ? images.micTurnOn : images.micTurnOff)
                        .foregroundColor(participant.hasAudio ? colors.text : colors.accentRed)

                    (participant.hasVideo ? images.videoTurnOn : images.videoTurnOff)
                        .foregroundColor(participant.hasVideo ? colors.text : colors.accentRed)
                }
            }
            Divider()
        }
    }
}

extension CallParticipant {
    
    var renderingId: String {
        "\(trackLookupPrefix ?? id)-\(isOnline)-\(hasAudio)-\(shouldDisplayTrack)"
    }
}
