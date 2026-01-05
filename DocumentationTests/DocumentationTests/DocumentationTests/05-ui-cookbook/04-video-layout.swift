//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {

    container {
        struct JoinCallView: View {

            @State var callId = ""
            @ObservedObject var viewModel: CallViewModel

            var body: some View {
                VStack {
                    TextField("Insert call id", text: $callId)
                    Button {
                        resignFirstResponder()
                        viewModel.startCall(callType: .default, callId: callId, members: [])
                    } label: {
                        Text("Join call")
                    }
                    Spacer()
                }
                .padding()
            }
        }

        struct HomeView<Factory: ViewFactory>: View {

            @ObservedObject var appState: AppState

            var viewFactory: Factory
            @StateObject var viewModel = CallViewModel()

            var body: some View {
                ZStack {
                    JoinCallView(viewModel: viewModel)

                    if viewModel.callingState == .joining {
                        ProgressView()
                    } else if viewModel.callingState == .inCall {
                        CallView(viewFactory: viewFactory, viewModel: viewModel)
                    }
                }
            }
        }

        container {
            @MainActor
            struct CustomView {
                var participants: [CallParticipant] {
                    viewModel.callParticipants
                        .map(\.value)
                        .sorted(by: defaultComparators)
                }
            }
        }

        container {
            struct CustomCallControlsView: View {

                @ObservedObject var viewModel: CallViewModel

                var body: some View {
                    HStack(spacing: 32) {
                        VideoIconView(viewModel: viewModel)
                        MicrophoneIconView(viewModel: viewModel)
                        ToggleCameraIconView(viewModel: viewModel)
                        HangUpIconView(viewModel: viewModel)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 85)
                }
            }

            struct BottomParticipantView: View {

                var participant: CallParticipant

                var body: some View {
                    UserAvatar(imageURL: participant.profileImageURL, size: 80)
                        .overlay(
                            !participant.hasAudio ?
                                BottomRightView {
                                    MuteIndicatorView()
                                }
                                : nil
                        )
                }
            }

            struct MuteIndicatorView: View {

                var body: some View {
                    Image(systemName: "mic.slash.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14)
                        .padding(.all, 12)
                        .foregroundColor(.gray)
                        .background(Color.black)
                        .clipShape(Circle())
                        .offset(x: 4, y: 8)
                }
            }

            struct CustomView: View {
                var body: some View {
                    VStack {
                        ZStack {
                            GeometryReader { reader in
                                if let dominantSpeaker = participants.first {
                                    VideoCallParticipantView(
                                        participant: dominantSpeaker,
                                        availableFrame: reader.frame(in: .global),
                                        contentMode: .scaleAspectFit,
                                        customData: customData,
                                        call: call
                                    )
                                }

                                VStack {
                                    Spacer()
                                    CustomCallControlsView(viewModel: viewModel)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cornerRadius(32)
                        .padding(.bottom)
                        .padding(.horizontal)

                        ScrollView(.horizontal) {
                            HStack {
                                ForEach(participants.dropFirst()) { participant in
                                    BottomParticipantView(participant: participant)
                                }
                            }
                        }
                        .padding(.all, 32)
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                    }
                    .background(Color.black)
                }
            }
        }
    }
}
