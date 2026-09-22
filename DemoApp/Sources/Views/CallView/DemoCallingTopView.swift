//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import GoogleSignIn
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallingTopView: View {

    @Injected(\.videoAppearance) var videoAppearance

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
        HStack(spacing: tokens.layout.spacingXs) {
            if AppEnvironment.configuration.isRelease {
                Label {
                    Text(username)
                        .font(tokens.fonts.bodyBold)
                        .foregroundColor(Color(tokens.colors.textPrimary))
                } icon: {
                    AppUserView(user: currentUser, overrideUserName: username)
                }
            } else {
                Button {
                    logoutAlertShown = !AppEnvironment.configuration.isRelease
                } label: {
                    Label {
                        Text(username)
                            .font(tokens.fonts.bodyBold)
                            .foregroundColor(Color(tokens.colors.textPrimary))
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
                        .font(tokens.fonts.body)
                        .foregroundColor(Color(tokens.colors.textPrimary))
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

    private var tokens: DesignSystemTokens { videoAppearance.tokens }
}
