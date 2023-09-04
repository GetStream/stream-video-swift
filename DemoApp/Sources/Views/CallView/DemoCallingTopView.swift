//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct DemoCallingTopView: View {

    @Injected(\.streamVideo) var streamVideo

    @State var logoutAlertShown = false

    var body: some View {
        HStack {
            if AppEnvironment.configuration.isRelease {
                Label {
                    Text(streamVideo.user.name)
                        .bold()
                        .foregroundColor(.primary)
                } icon: {
                    UserAvatar(imageURL: streamVideo.user.imageURL, size: 32)
                        .accessibilityIdentifier("userAvatar")
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
                        UserAvatar(imageURL: streamVideo.user.imageURL, size: 32)
                            .accessibilityIdentifier("userAvatar")
                    }
                }
            }

            Spacer()
        }
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

