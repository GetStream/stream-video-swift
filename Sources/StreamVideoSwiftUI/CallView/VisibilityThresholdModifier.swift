//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// The modifier designed to dynamically track and respond to the visibility status of a view within its parent
/// bounds or viewport. It utilises a user-defined visibility threshold, represented as a percentage, to
/// determine how much of the view should be visible (both vertically and horizontally) before it's considered
/// "on screen".
///
/// When the visibility state of the view changes (i.e., it transitions between being "on screen" and "off screen"),
/// a callback is triggered to notify the user of this change. This can be particularly useful in scenarios where
/// resource management is crucial, such as video playback or dynamic content loading, where actions might
/// be triggered based on whether a view is currently visible to the user.
///
/// By default, the threshold is set to 30%, meaning 30% of the view's dimensions must be within the parent's
/// bounds for it to be considered visible.
struct VisibilityThresholdModifier: ViewModifier {
    /// State to track if the content view is on screen.
    @State private var isOnScreen: Bool? {
        didSet { if isOnScreen != oldValue, let isOnScreen { changeHandler(isOnScreen) } }
    }

    /// The bounds of the parent view or viewport.
    var bounds: CGRect
    /// The threshold percentage of the view that must be visible.
    var threshold: CGFloat
    /// Closure to handle visibility changes.
    var changeHandler: (Bool) -> Void

    init(
        in bounds: CGRect,
        threshold: CGFloat,
        changeHandler: @escaping (Bool) -> Void
    ) {
        self.bounds = bounds
        self.threshold = threshold
        self.changeHandler = changeHandler
    }

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry -> Color in
                    /// Convert the local frame of the content to a global frame.
                    let geometryInGlobal = geometry.frame(in: .global)

                    let (verticalVisible, horizontalVisible) = calculateVisibilityInBothAxis(in: geometryInGlobal)

                    /// Update the isOnScreen state based on visibility calculations.
                    Task { @MainActor in
                        self.isOnScreen = verticalVisible && horizontalVisible
                    }

                    /// Use a clear color for the background to not affect the appearance.
                    return Color.clear
                }
            )
    }

    func calculateVisibilityInBothAxis(in rect: CGRect) -> (verticalVisible: Bool, horizontalVisible: Bool) {
        /// Calculate the global minY, maxY, minX, and maxX of the content view.
        let minY = rect.minY
        let maxY = rect.maxY
        let minX = rect.minX
        let maxX = rect.maxX

        /// Calculate required height and width based on visibility threshold.
        let requiredHeight = rect.size.height * threshold
        let requiredWidth = rect.size.width * threshold

        /// Check if the content view is vertically within the parent's bounds.
        let verticalVisible = (minY + requiredHeight <= bounds.maxY && minY >= bounds.minY) ||
            (maxY - requiredHeight >= bounds.minY && maxY <= bounds.maxY)
        /// Check if the content view is horizontally within the parent's bounds.
        let horizontalVisible = (minX + requiredWidth <= bounds.maxX && minX >= bounds.minX) ||
            (maxX - requiredWidth >= bounds.minX && maxX <= bounds.maxX)

        return (verticalVisible, horizontalVisible)
    }
}

extension View {
    /// Attaches a visibility observation modifier to the view.
    ///
    /// - Parameters:
    ///   - bounds: The bounds of the parent view or viewport within which the visibility of the view will
    ///   be tracked.
    ///   - threshold: A percentage value (defaulted to 0.3 or 30%) representing how much of the view
    ///   should be visible within the `bounds` before it's considered "on screen".
    ///   - changeHandler: A closure that gets triggered with a Boolean value indicating the visibility
    ///   state of the view whenever it changes.
    ///
    /// - Returns: A modified view that observes its visibility status within the specified bounds.
    @ViewBuilder
    func visibilityObservation(
        in bounds: CGRect,
        threshold: CGFloat = 0.3,
        changeHandler: @escaping (Bool) -> Void
    ) -> some View {
        modifier(
            VisibilityThresholdModifier(
                in: bounds,
                threshold: threshold,
                changeHandler: changeHandler
            )
        )
    }
}
