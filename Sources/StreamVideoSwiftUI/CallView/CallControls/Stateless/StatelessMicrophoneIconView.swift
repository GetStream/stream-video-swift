//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless microphone icon button.
public struct StatelessMicrophoneIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The associated call for the microphone icon.
    public var call: Call?

    /// The size of the microphone icon.
    public var size: CGFloat

    /// The action handler for the microphone icon button.
    public var actionHandler: ActionHandler?

    @ObservedObject private var callSettings: CallSettings

    /// Initializes a stateless microphone icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the microphone icon.
    ///   - size: The size of the microphone icon.
    ///   - actionHandler: An optional closure to handle button tap actions.
    @MainActor
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

    /// The body of the microphone icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: callSettings.audioOn
                        ? images.micTurnOn
                        : images.micTurnOff,
                    size: size,
                    iconStyle: callSettings.audioOn
                        ? .transparent
                        : .disabled
                )
            }
        )
        .accessibility(identifier: "microphoneToggle")
        .streamAccessibility(value: callSettings.audioOn ? "1" : "0")
    }
}
