//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless microphone icon button.
public struct StatelessMicrophoneIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The size of the toggle camera icon.
    var size: CGFloat

    /// The action handler for the toggle camera icon button.
    var actionHandler: ActionHandler?

    var publisher: AnyPublisher<Bool, Never>?

    @State var isEnabled: Bool

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
        self.size = size
        isEnabled = call?.state.callSettings.audioOn ?? false
        publisher = call?
            .state
            .$callSettings
            .compactMap(\.audioOn)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        self.actionHandler = actionHandler
    }

    /// The body of the microphone icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: isEnabled
                        ? images.micTurnOn
                        : images.micTurnOff,
                    size: size,
                    iconStyle: isEnabled
                        ? .transparent
                        : .disabled
                )
            }
        )
        .accessibility(identifier: "microphoneToggle")
        .streamAccessibility(value: isEnabled ? "1" : "0")
        .onReceive(publisher) { isEnabled = $0 }
    }
}
