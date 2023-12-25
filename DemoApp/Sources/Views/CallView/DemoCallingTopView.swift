//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI
import GoogleSignIn

struct DemoCallingTopView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors

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
            }

            Spacer()

            if GIDSignIn.sharedInstance.currentUser != nil {
                NavigationLink {
                    DemoCallsView(callViewModel: callViewModel)
                } label: {
                    Text("Calls")
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

