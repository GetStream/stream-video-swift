//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless microphone icon button.
public struct StatelessMicrophoneIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images
    @Injected(\.permissions) private var permissions
    @Injected(\.videoAppearance) private var videoAppearance

    /// The associated call for the microphone icon.
    public weak var call: Call?

    /// The size of the microphone icon.
    public var size: CGFloat

    /// The action handler for the microphone icon button.
    public var actionHandler: ActionHandler?

    public var controlStyle: ToggleControlStyle

    @ObservedObject private var callSettings: CallSettings

    @State private var hasPermission: Bool
    @State private var canRequestPermission: Bool

    /// Initializes a stateless microphone icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the microphone icon.
    ///   - size: The size of the microphone icon.
    ///   - actionHandler: An optional closure to handle button tap actions.
    @MainActor
    public init(
        call: Call?,
        callSettings: CallSettings = .default,
        size: CGFloat = 44,
        controlStyle: ToggleControlStyle = .init(
            enabled: .init(icon: Appearance.default.images.micTurnOn, iconStyle: .transparent),
            disabled: .init(icon: Appearance.default.images.micTurnOff, iconStyle: .disabled)
        ),
        actionHandler: ActionHandler? = nil
    ) {
        self.call = call
        self.size = size
        _callSettings = .init(wrappedValue: call?.state.callSettings ?? callSettings)
        self.controlStyle = controlStyle
        self.actionHandler = actionHandler
        hasPermission = InjectedValues[\.permissions].hasMicrophonePermission
        canRequestPermission = InjectedValues[\.permissions].canRequestMicrophonePermission
    }

    /// The body of the microphone icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                label(
                    isEnabled: callSettings.audioOn,
                    hasPermission: hasPermission,
                    canRequestPermission: canRequestPermission
                )
            }
        )
        .disabled(!hasPermission && !canRequestPermission)
        .accessibility(identifier: "microphoneToggle")
        .streamAccessibility(value: callSettings.audioOn ? "1" : "0")
        .onReceive(permissions.$hasMicrophonePermission) { hasPermission = $0 }
        .onReceive(permissions.$canRequestMicrophonePermission) { canRequestPermission = $0 }
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func label(
        isEnabled: Bool,
        hasPermission: Bool,
        canRequestPermission: Bool
    ) -> some View {
        let style = controlStyle(
            isEnabled: isEnabled,
            hasPermission: hasPermission,
            canRequestPermission: canRequestPermission
        )
        let content = CallIconView(
            icon: style.icon,
            size: size,
            iconStyle: style.iconStyle
        )

        if hasPermission || canRequestPermission {
            content
        } else {
            content
                .badge(
                    videoAppearance.images.callControlErrorBadge,
                    foreground: Color(
                        videoAppearance.colors.controlCallControlErrorBadgeText
                    ),
                    background: Color(
                        videoAppearance.colors
                            .controlCallControlErrorBadgeBackground
                    )
                )
        }
    }

    private func controlStyle(
        isEnabled: Bool,
        hasPermission: Bool,
        canRequestPermission: Bool
    ) -> ControlStyle {
        if !hasPermission, !canRequestPermission {
            return controlStyle.permissionDenied
        } else if isEnabled, hasPermission {
            return controlStyle.enabled
        } else {
            return controlStyle.disabled
        }
    }
}
