//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// `CornerClipper` is a ViewModifier that clips a SwiftUI view
/// to have rounded corners on specified sides.
public struct CornerClipper: ViewModifier {

    /// The radius of the rounded corners.
    public var radius: CGFloat

    /// The corners that should be rounded.
    public var corners: UIRectCorner

    /// The background color that should extend below/above safeArea.
    public var backgroundColor: Color

    /// Modifies the provided content by clipping it to the shape with rounded corners.
    /// - Parameter content: The content view to be modified.
    public func body(content: Content) -> some View {
        ZStack {
            backgroundColor
                .clipShape(RoundedCorners(radius: radius, corners: corners))

            backgroundColorView

            content
                .layoutPriority(1)
        }
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
/// on the specified sides using a given radius.
public struct RoundedCorners: Shape {

    /// The radius of the rounded corners.
    public var radius: CGFloat = .infinity

    /// The corners to be rounded.
    public var corners: UIRectCorner = .allCorners

    /// Creates a path for the current shape.
    /// - Parameter rect: The rectangle in which the path should be created.
    public func path(in rect: CGRect) -> Path {
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
    public func clipCorners(
        radius: CGFloat,
        corners: UIRectCorner,
        backgroundColor: Color = .clear
    ) -> some View {
        modifier(
            CornerClipper(
                radius: radius,
                corners: corners,
                backgroundColor: backgroundColor
            )
        )
    }
}
