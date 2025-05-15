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

    /// The associated call for the video icon.
    public weak var call: Call?

    /// The size of the video icon.
    public var size: CGFloat

    /// The action handler for the video icon button.
    public var actionHandler: ActionHandler?

    @ObservedObject private var callSettings: CallSettings

    /// Initializes a stateless video icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the video icon.
    ///   - size: The size of the video icon.
    ///   - actionHandler: An optional closure to handle button tap actions.
    public init(
        call: Call?,
        size: CGFloat = 44,
        actionHandler: ActionHandler? = nil
    ) {
        self.call = call
        self.size = size
        _callSettings = .init(wrappedValue: call?.state.callSettings ?? .init())
        self.actionHandler = actionHandler
    }

    /// The body of the video icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: callSettings.videoOn
                        ? images.videoTurnOn
                        : images.videoTurnOff,
                    size: size,
                    iconStyle: callSettings.videoOn
                        ? .transparent
                        : .disabled
                )
            }
        )
        .accessibility(identifier: "cameraToggle")
        .streamAccessibility(value: callSettings.videoOn ? "1" : "0")
    }
}
