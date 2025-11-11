//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless video icon button.
public struct StatelessVideoIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images
    @Injected(\.permissions) private var permissions

    /// The associated call for the video icon.
    public weak var call: Call?

    /// The size of the video icon.
    public var size: CGFloat

    /// The action handler for the video icon button.
    public var actionHandler: ActionHandler?

    public var controlStyle: ToggleControlStyle

    @ObservedObject private var callSettings: CallSettings

    @State private var hasPermission: Bool
    @State private var canRequestPermission: Bool

    /// Initializes a stateless video icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the video icon.
    ///   - size: The size of the video icon.
    ///   - actionHandler: An optional closure to handle button tap actions.
    public init(
        call: Call?,
        callSettings: CallSettings = .default,
        size: CGFloat = 44,
        controlStyle: ToggleControlStyle = .init(
            enabled: .init(icon: Appearance.default.images.videoTurnOn, iconStyle: .transparent),
            disabled: .init(icon: Appearance.default.images.videoTurnOff, iconStyle: .disabled)
        ),
        actionHandler: ActionHandler? = nil
    ) {
        self.call = call
        self.size = size
        _callSettings = .init(wrappedValue: call?.state.callSettings ?? callSettings)
        self.controlStyle = controlStyle
        self.actionHandler = actionHandler
        hasPermission = InjectedValues[\.permissions].hasCameraPermission
        canRequestPermission = InjectedValues[\.permissions].canRequestCameraPermission
    }

    /// The body of the video icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: { label(isEnabled: callSettings.videoOn, hasPermission: hasPermission) }
        )
        .disabled(!hasPermission && !canRequestPermission)
        .accessibility(identifier: "cameraToggle")
        .streamAccessibility(value: callSettings.videoOn ? "1" : "0")
        .onReceive(permissions.$hasCameraPermission) { hasPermission = $0 }
        .onReceive(permissions.$canRequestCameraPermission) { canRequestPermission = $0 }
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func label(isEnabled: Bool, hasPermission: Bool) -> some View {
        let content = CallIconView(
            icon: isEnabled && hasPermission
                ? controlStyle.enabled.icon
                : controlStyle.disabled.icon,
            size: size,
            iconStyle: isEnabled && hasPermission
                ? controlStyle.enabled.iconStyle
                : controlStyle.disabled.iconStyle
        )

        if hasPermission || canRequestPermission {
            content
        } else {
            content
                .badge(Image(systemName: "exclamationmark"), background: .orange)
        }
    }
}
