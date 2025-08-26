//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view that prompts users to grant camera and microphone permissions when
/// they are missing. Provides a direct link to the app's settings.
public struct PermissionsPromptView: View {

    @Injected(\.urlNavigator) private var urlNavigator

    @ObservedObject private var permissions = InjectedValues[\.permissions]
    @State private var presentNavigationPopup = false
    @State private var isHidden = false

    public init() {}

    public var body: some View {
        if (!permissions.hasCameraPermission || !permissions.hasMicrophonePermission), !isHidden {
            HStack {
                title
                Spacer()
                actionsContainerView
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .modifier(ShadowViewModifier())
            .alert(isPresented: $presentNavigationPopup) { alertContentView }
        }
    }

    @ViewBuilder
    private var title: some View {
        switch (permissions.hasCameraPermission, permissions.hasMicrophonePermission) {
        case (false, false):
            text(for: L10n.Call.Permissions.Missing.cameraandmic)

        case (false, true):
            text(for: L10n.Call.Permissions.Missing.camera)

        case (true, false):
            text(for: L10n.Call.Permissions.Missing.mic)

        case (true, true):
            EmptyView()
        }
    }

    @ViewBuilder
    private func text(for string: String) -> some View {
        Text(string)
            .font(.headline)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
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
            if #available(iOS 14.0, *) {
                Label {
                    Text(L10n.Call.Permissions.Missing.Cta.title)
                } icon: {
                    Image(systemName: "gear")
                }
                .minimumScaleFactor(0.7)
            } else {
                Text("\(Image(systemName: "gear")) \(Text(L10n.Call.Permissions.Missing.Cta.title))")
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .foregroundColor(.white)
        .background(Color.blue)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var alertContentView: Alert {
        Alert(
            title: Text(L10n.Call.Permissions.Missing.Prompt.title),
            message: Text(L10n.Call.Permissions.Missing.Prompt.message),
            primaryButton: .default(
                Text(L10n.Alert.Actions.continue),
                action: { try? urlNavigator.openSettings() }
            ),
            secondaryButton: .cancel {
                isHidden = true
            }
        )
    }
}
