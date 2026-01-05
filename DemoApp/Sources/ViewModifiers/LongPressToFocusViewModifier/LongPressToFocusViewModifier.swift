//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamVideo
import SwiftUI

/// A `ViewModifier` that adds a long press to focus gesture to a SwiftUI view.
struct LongPressToFocusViewModifier: ViewModifier {

    /// The frame within which the focus gesture can be recognized.
    var availableFrame: CGRect

    /// The handler to call with the focus point when the gesture is recognized.
    var handler: (CGPoint) -> Void

    /// Modifies the content by adding a long press gesture recognizer.
    ///
    /// - Parameter content: The content to be modified.
    /// - Returns: The modified content with the long press to focus gesture added.
    func body(content: Content) -> some View {
        content
            // https://developer.apple.com/forums/thread/127277
            // When scrolling the participants list, the swipe gesture is being
            // overridden from the LonPress gesture below. The TapGesture is added
            // here to give priority on scrolling over LongPress.
            .onTapGesture {}
            .gesture(
                // A long press gesture requiring a minimum of 0.5 seconds to be recognized.
                LongPressGesture(minimumDuration: 0.5)
                    // Sequence the long press gesture with a drag gesture in the local coordinate space.
                    .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                    .onEnded { value in
                        // Handle the end of the gesture sequence.
                        switch value {
                        // If the long press gesture was succeeded by a drag gesture.
                        case .second(true, let drag):
                            // If the drag gesture has a valid location.
                            if let location = drag?.location {
                                // Convert the point to the focus interest point and call the handler.
                                handler(convertToPointOfInterest(location))
                            }
                        // All other cases do nothing.
                        default:
                            break
                        }
                    }
            )
    }

    /// Converts a point within the view's coordinate space to a point of interest for camera focus.
    ///
    /// The conversion is based on the `availableFrame` property, flipping the axis
    /// and normalizing the point to the range [0, 1].
    ///
    /// - Parameter point: The point to convert.
    /// - Returns: The converted point of interest.
    func convertToPointOfInterest(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.y / availableFrame.height,
            y: 1.0 - point.x / availableFrame.width
        )
    }
}

extension View {

    /// Adds a long press to focus gesture to the view.
    ///
    /// - Parameters:
    ///   - availableFrame: The frame within which the focus gesture can be recognized.
    ///   - handler: The closure to call with the focus point when the gesture is recognized.
    /// - Returns: A modified view with the long press to focus gesture added.
    @ViewBuilder
    func longPressToFocus(
        availableFrame: CGRect,
        handler: @escaping (CGPoint) -> Void
    ) -> some View {
        // Apply the view modifier to add the gesture to the view.
        modifier(
            LongPressToFocusViewModifier(
                availableFrame: availableFrame,
                handler: handler
            )
        )
    }
}
