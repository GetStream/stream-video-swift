//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamVideo
import SwiftUI

/// A view representing a stateless video icon button.
public struct StatelessVideoIconView: View {

    /// Defines a closure type for action handling.
    public typealias ActionHandler = () -> Void

    @Injected(\.images) private var images

    /// The size of the toggle camera icon.
    var size: CGFloat

    /// The action handler for the toggle camera icon button.
    var actionHandler: ActionHandler?

    var publisher: AnyPublisher<Bool, Never>?

    @State var isEnabled: Bool

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
        self.size = size
        isEnabled = call?.state.callSettings.videoOn ?? false
        publisher = call?
            .state
            .$callSettings
            .compactMap(\.videoOn)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        self.actionHandler = actionHandler
    }

    /// The body of the video icon view.
    public var body: some View {
        Button(
            action: { actionHandler?() },
            label: {
                CallIconView(
                    icon: isEnabled
                        ? images.videoTurnOn
                        : images.videoTurnOff,
                    size: size,
                    iconStyle: isEnabled
                        ? .transparent
                        : .disabled
                )
            }
        )
        .accessibility(identifier: "cameraToggle")
        .streamAccessibility(value: isEnabled ? "1" : "0")
        .onReceive(publisher) { isEnabled = $0 }
    }
}
