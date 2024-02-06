//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
    @State var logoutAlertShown = false

    var body: some View {
        HStack {
            if AppEnvironment.configuration.isRelease {
                Label {
                    Text(streamVideo.user.name)
                        .bold()
                        .foregroundColor(.primary)
                } icon: {
                    AppUserView(user: streamVideo.user)
                }
            } else {
                Button {
                    logoutAlertShown = !AppEnvironment.configuration.isRelease
                } label: {
                    Label {
                        Text(streamVideo.user.name)
                            .bold()
                            .foregroundColor(.primary)
                    } icon: {
                        AppUserView(user: streamVideo.user)
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
