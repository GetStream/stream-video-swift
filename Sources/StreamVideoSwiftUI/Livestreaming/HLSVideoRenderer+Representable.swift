//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo
import SwiftUI
import UIKit

extension HLSVideoRenderer {

    /// Hosts the ``HLSPlayerView`` that shows the player of the call.
    struct Representable: UIViewRepresentable {

        var call: Call
        var contentMode: UIView.ContentMode
        var onPlayerReady: (@MainActor () async -> Void)?

        /// Creates the coordinator that owns the claim on the player.
        func makeCoordinator() -> Coordinator {
            Coordinator(call: call, onPlayerReady: onPlayerReady)
        }

        func makeUIView(context: Context) -> HLSPlayerView {
            let view = HLSPlayerView()
            view.backgroundColor = .clear
            view.videoGravity = videoGravity(for: contentMode)
            context.coordinator.attach(to: view)
            return view
        }

        func updateUIView(_ uiView: HLSPlayerView, context: Context) {
            uiView.videoGravity = videoGravity(for: contentMode)
            context.coordinator.update(call: call)
        }

        /// Gives the player back when the view goes away.
        static func dismantleUIView(
            _ uiView: HLSPlayerView,
            coordinator: Coordinator
        ) {
            coordinator.dismantle()
        }

        private func videoGravity(for contentMode: UIView.ContentMode) -> AVLayerVideoGravity {
            switch contentMode {
            case .scaleAspectFill:
                return .resizeAspectFill
            case .scaleToFill:
                return .resize
            default:
                return .resizeAspect
            }
        }
    }
}
