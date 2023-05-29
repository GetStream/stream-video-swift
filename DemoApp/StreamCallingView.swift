//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Intents
import NukeUI
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct StreamCallingView: View {
    
    @Injected(\.colors) var colors
    @Injected(\.streamVideo) var streamVideo

    @State var text = ""
    @State var logoutAlertShown = false

    @ObservedObject var appState = AppState.shared
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    logoutAlertShown = true
                } label: {
                    HStack {
                        UserAvatar(imageURL: streamVideo.user.imageURL, size: 32)
                            .accessibilityIdentifier("userAvatar")
                        Text(streamVideo.user.name)
                            .bold()
                            .foregroundColor(.primary)
                        Spacer()
                    }
                }

                Spacer()
            }
                                    
            Spacer()
            
            Image("video")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 114)
            
            Text("Stream Video Calling")
                .font(.title)
                .bold()
                .padding()
            
            Text("Build reliable video calling, audio rooms, and live streaming with our easy-to-use SDKs and global edge network")
                .multilineTextAlignment(.center)
                .foregroundColor(Color(colors.textLowEmphasis))
                .padding()
            
            HStack {
                Text("Call ID number")
                    .font(.caption)
                    .foregroundColor(Color(colors.textLowEmphasis))
                Spacer()
            }
            
            HStack {
                TextField("Call ID", text: $text)
                    .padding(.all, 12)
                    .background(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 1)
                    )
                Button {
                    resignFirstResponder()
                    viewModel.enterLobby(callId: text, type: .default, members: [])
                } label: {
                    CallButtonView(title: "Join Call", maxWidth: 120)
                }
            }
            
            HStack {
                Text("Don't have a Call ID?")
                    .font(.caption)
                    .foregroundColor(Color(colors.textLowEmphasis))
                Spacer()
            }
            .padding(.top)
            
            Button {
                resignFirstResponder()
                viewModel.startCall(callId: UUID().uuidString, type: .default, members: [])
            } label: {
                CallButtonView(title: "Start New Call")
            }
            .padding(.bottom)
            
            Spacer()
        }
        .padding()
        .background(colors.lobbyBackground.edgesIgnoringSafeArea(.all))
        .preferredColorScheme(.dark)
        .alert(isPresented: $logoutAlertShown) {
            Alert(
                title: Text("Sign out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign out")) {
                    withAnimation {
                        AppState.shared.logout()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}

struct CallButtonView: View {
    
    @Injected(\.colors) var colors
    
    var title: String
    var maxWidth: CGFloat?
    
    var body: some View {
        Text(title)
            .bold()
            .foregroundColor(.white)
            .padding(.all, 12)
            .frame(maxWidth: maxWidth ?? .infinity)
            .background(colors.primaryButtonBackground)
            .cornerRadius(8)
    }
    
}

