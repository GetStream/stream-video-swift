//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        // Create the call with the callType and id
        let call = streamVideo.call(callType: "default", callId: "123")

        // Create the call on server side
        let creationResult = try await call.create()

        // Join the call
        let joinResult = try await call.join()
    }

    asyncContainer {
        // Retrieve the desired focus point(e.g using a tap or longPress gesture)
        let focusPoint: CGPoint = CGPoint(x: 50, y: 50)

        // and pass it to our call
        try await call.focus(at: focusPoint)
    }

    container {
        struct LongPressToFocusViewModifier: ViewModifier {

            var availableFrame: CGRect

            var handler: (CGPoint) -> Void

            func body(content: Content) -> some View {
                content
                    .gesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                            .onEnded { value in
                                switch value {
                                case .second(true, let drag):
                                    if let location = drag?.location {
                                        handler(convertToPointOfInterest(location))
                                    }
                                default:
                                    break
                                }
                            }
                    )
            }

            func convertToPointOfInterest(_ point: CGPoint) -> CGPoint {
                CGPoint(
                    x: point.y / availableFrame.height,
                    y: 1.0 - point.x / availableFrame.width
                )
            }
        }
    }

    container {
        class CustomViewFactory: ViewFactory {

            func makeVideoParticipantView(
                participant: CallParticipant,
                id: String,
                availableFrame: CGRect,
                contentMode: UIView.ContentMode,
                customData: [String: RawJSON],
                call: Call?
            ) -> some View {
                DefaultViewFactory.shared.makeVideoParticipantView(
                    participant: participant,
                    id: id,
                    availableFrame: availableFrame,
                    contentMode: contentMode,
                    customData: customData,
                    call: call
                )
                .longPressToFocus(availableFrame: availableFrame) { point in
                    Task {
                        guard call?.state.sessionId == participant.sessionId
                        else { return } // We are using this to only allow long pressing on our local video feed
                        try await call?.focus(at: point)
                    }
                }
            }
        }
    }
}
