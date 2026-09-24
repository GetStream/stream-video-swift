//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// A view that prompts users to grant camera and microphone permissions when
/// they are missing. Provides a direct link to the app's settings.
public struct PermissionsPromptView: View {

    @Injected(\.urlNavigator) private var urlNavigator
    @Injected(\.videoAppearance) private var videoAppearance

    private let ownCapabilitiesPublisher: AnyPublisher<Set<OwnCapability>, Never>?

    @ObservedObject private var permissions = InjectedValues[\.permissions]

    @State private var presentNavigationPopup = false
    @State private var isHidden = false
    @State private var requiresCameraPermission: Bool
    @State private var requiresMicrophonePermission: Bool

    public init(call: Call?) {
        let ownCapabilities = Set(call?.state.ownCapabilities ?? [])
        requiresCameraPermission = ownCapabilities.contains(.sendVideo)
        requiresMicrophonePermission = ownCapabilities.contains(.sendAudio)
        ownCapabilitiesPublisher = call?
            .state
            .$ownCapabilities
            .map(Set.init)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public var body: some View {
        Group {
            if (isMissingCameraPermission || isMissingMicrophonePermission), !isHidden {
                HStack(spacing: layout.spacingXs) {
                    title
                    Spacer()
                    actionsContainerView
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(layout.spacingXs)
                .modifier(ShadowViewModifier())
                .alert(isPresented: $presentNavigationPopup) { alertContentView }
            }
        }
        .onReceive(ownCapabilitiesPublisher) {
            requiresCameraPermission = $0.contains(.sendVideo)
            requiresMicrophonePermission = $0.contains(.sendAudio)
        }
    }

    @ViewBuilder
    private var title: some View {
        switch (isMissingCameraPermission, isMissingMicrophonePermission) {
        case (false, false):
            EmptyView()

        case (true, false):
            text(for: L10n.Call.Permissions.Missing.camera)

        case (false, true):
            text(for: L10n.Call.Permissions.Missing.mic)

        case (true, true):
            text(for: L10n.Call.Permissions.Missing.cameraandmic)
        }
    }

    @ViewBuilder
    private func text(for string: String) -> some View {
        Text(string)
            .font(fonts.headline)
            .foregroundColor(Color(colors.textPrimary))
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.leading)
            .lineLimit(3)
    }

    @ViewBuilder
    private var actionsContainerView: some View {
        HStack(spacing: layout.spacingXs) {
            goToSettingsButton
        }
    }

    @ViewBuilder
    private var goToSettingsButton: some View {
        Button {
            presentNavigationPopup = true
        } label: {
            settingsButtonLabel
        }
        .padding(.vertical, layout.spacingXxs)
        .padding(.horizontal, layout.spacingXs)
        .foregroundColor(Color(colors.buttonPrimaryTextOnAccent))
        .background(Color(colors.buttonPrimaryBackground))
        .clipShape(RoundedRectangle(cornerRadius: layout.radiusMd))
    }

    @ViewBuilder
    private var settingsButtonLabel: some View {
        if #available(iOS 14.0, *) {
            Label {
                Text(L10n.Call.Permissions.Missing.Cta.title)
            } icon: {
                videoAppearance.images.settings
            }
            .minimumScaleFactor(0.7)
        } else {
            HStack(alignment: .center, spacing: layout.spacingXxs) {
                videoAppearance.images.settings
                Text(L10n.Call.Permissions.Missing.Cta.title)
            }
            .minimumScaleFactor(0.7)
        }
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

    private var isMissingCameraPermission: Bool {
        requiresCameraPermission && !permissions.hasCameraPermission && !permissions.canRequestCameraPermission
    }

    private var isMissingMicrophonePermission: Bool {
        requiresMicrophonePermission && !permissions.hasMicrophonePermission && !permissions.canRequestMicrophonePermission
    }
}
