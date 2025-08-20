//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct PermissionsPromptView: View {

    @Injected(\.urlNavigator) private var urlNavigator

    @ObservedObject private var permissions = InjectedValues[\.permissions]
    @State private var presentNavigationPopup = false

    public init() {}

    public var body: some View {
        if !permissions.hasCameraPermission || !permissions.hasMicrophonePermission {
            HStack {
                title
                Divider()
                actionsContainerView
            }
            .padding(.all, 8)
            .modifier(ShadowViewModifier())
            .frame(maxHeight: 80)
            .alert(isPresented: $presentNavigationPopup) { alertContentView }
        }
    }

    @ViewBuilder
    private var title: some View {
        switch (permissions.hasCameraPermission, permissions.hasMicrophonePermission) {
        case (false, false):
            Text("Please grant permission to access your camera and microphone.")
                .font(.headline)
                .minimumScaleFactor(0.7)

        case (false, true):
            Text("Please grant permission to access your camera.")
                .font(.headline)
                .minimumScaleFactor(0.7)

        case (true, false):
            Text("Please grant permission to access your microphone.")
                .font(.headline)
                .minimumScaleFactor(0.7)

        case (true, true):
            EmptyView()
        }
    }

    @ViewBuilder
    private var actionsContainerView: some View {
        HStack {
            goToSettingsButton
        }
    }

    @ViewBuilder
    private var goToSettingsButton: some View {
        Button {
            presentNavigationPopup = true
        } label: {
            Text("Open Settings")
        }
    }

    private var alertContentView: Alert {
        .init(
            title: Text("Info"),
            message: Text(
                "After toggling any of the settings in the system settings, the app will restart automatically. You will need to join the call again."
            ),
            dismissButton:
            .default(
                Text("Continue"),
                action: { try? urlNavigator.openSettings() }
            )
        )
    }
}
