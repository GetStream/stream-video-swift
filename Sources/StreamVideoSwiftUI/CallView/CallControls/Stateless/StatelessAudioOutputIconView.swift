//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless audio output icon button.
public struct StatelessAudioOutputIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The associated call for the audio output icon.
    public weak var call: Call?

    /// The size of the audio output icon.
    public var size: CGFloat

    /// The action handler for the audio output icon button.
    public var actionHandler: ActionHandler?

    @ObservedObject private var callSettings: CallSettings

    /// Initializes a stateless audio output icon view.
    ///
    /// - Parameters:
    ///   - call: The associated call for the audio output icon.
    ///   - size: The size of the audio output icon.
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

    /// The body of the audio output icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: callSettings.audioOutputOn
                        ? images.speakerOn
                        : images.speakerOff,
                    size: size,
                    iconStyle: callSettings.audioOutputOn
                        ? .primary
                        : .transparent
                )
            }
        )
    }
}
