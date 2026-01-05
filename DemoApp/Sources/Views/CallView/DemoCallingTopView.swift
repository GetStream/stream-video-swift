//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import GoogleSignIn
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallingTopView: View {

    @Injected(\.colors) var colors

    @ObservedObject var streamVideo = InjectedValues[\.streamVideo]
    @ObservedObject var callViewModel: CallViewModel
    @ObservedObject var appState: AppState = .shared
    @State var logoutAlertShown = false

    private var currentUser: User {
        appState.currentUser ?? streamVideo.user
    }

    private var username: String {
        currentUser == .anonymous ? "Anonymous" : currentUser.name
    }

    var body: some View {
        HStack {
            if AppEnvironment.configuration.isRelease {
                Label {
                    Text(username)
                        .bold()
                        .foregroundColor(.primary)
                } icon: {
                    AppUserView(user: currentUser, overrideUserName: username)
                }
            } else {
                Button {
                    logoutAlertShown = !AppEnvironment.configuration.isRelease
                } label: {
                    Label {
                        Text(username)
                            .bold()
                            .foregroundColor(.primary)
                    } icon: {
                        AppUserView(user: currentUser, overrideUserName: username)
                    }
                }
                .accessibilityIdentifier("userAvatar")
            }

            Spacer()

            if GIDSignIn.sharedInstance.currentUser != nil {
                NavigationLink {
                    DemoCallsView(callViewModel: callViewModel)
                } label: {
                    Text("Calls")
                        .foregroundColor(.primary)
                }
            }

            if !AppEnvironment.configuration.isRelease {
                DebugMenu()
            }
        }
        .alert(isPresented: $logoutAlertShown) {
            Alert(
                title: Text("Sign out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Sign out")) {
                    withAnimation {
                        AppState.shared.dispatchLogout()
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }
}
