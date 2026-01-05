//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// `CornerClipper` is a ViewModifier that clips a SwiftUI view
/// to have rounded corners on specified sides.
struct CornerClipper: ViewModifier {

    /// The radius of the rounded corners.
    var radius: CGFloat

    /// The corners that should be rounded.
    var corners: UIRectCorner

    /// The background color that should extend below/above safeArea.
    var backgroundColor: Color

    var extendToSafeArea = false

    /// Modifies the provided content by clipping it to the shape with rounded corners.
    /// The structure in the Z axis will be:
    /// 1. backgroundColor with roundedCorners.
    /// 2. backgroundColor without roundedCorners to fill in the safe are space that the above won't cover.
    /// 3. the content with a higher layoutPriority so the ZStack follow its size.
    /// - Parameter content: The content view to be modified.
    func body(content: Content) -> some View {
        ZStack {
            backgroundColor
                .clipShape(RoundedCorners(radius: radius, corners: corners))

            if extendToSafeArea {
                backgroundColorView
            }

            content
                .layoutPriority(1)
        }
        .edgesIgnoringSafeArea(.all)
    }

    private var backgroundColorView: some View {
        var edgeInsets = EdgeInsets()

        if corners.contains(.topLeft) || corners.contains(.topRight) {
            edgeInsets.top = radius
        }

        if corners.contains(.bottomLeft) || corners.contains(.bottomRight) {
            edgeInsets.bottom = radius
        }

        return backgroundColor
            .edgesIgnoringSafeArea(.all)
            .padding(.top, edgeInsets.top)
            .padding(.bottom, edgeInsets.bottom)
    }
}

/// `RoundedCorners` is a Shape used to create a rounded cornered rectangle
/// on the specified sides using a given radius.
struct RoundedCorners: Shape {

    /// The radius of the rounded corners.
    var radius: CGFloat = .infinity

    /// The corners to be rounded.
    var corners: UIRectCorner = .allCorners

    /// Creates a path for the current shape.
    /// - Parameter rect: The rectangle in which the path should be created.
    func path(in rect: CGRect) -> Path {
        Path(
            UIBezierPath(
                roundedRect: rect,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            ).cgPath
        )
    }
}

extension View {

    /// Clips the corners of the current view.
    /// - Parameters:
    ///   - radius: The radius for the rounded corners.
    ///   - corners: The corners that should be rounded.
    ///   - backgroundColor: The background color that should extend below/above safeArea.
    public func cornerRadius(
        _ radius: CGFloat,
        corners: UIRectCorner,
        backgroundColor: Color = .clear,
        extendToSafeArea: Bool = false
    ) -> some View {
        modifier(
            CornerClipper(
                radius: radius,
                corners: corners,
                backgroundColor: backgroundColor,
                extendToSafeArea: extendToSafeArea
            )
        )
    }
}
