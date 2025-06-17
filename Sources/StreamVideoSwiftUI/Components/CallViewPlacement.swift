//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// An enum representing the placement of a call view in different corners of a container.
public enum CallViewPlacement {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    func xOffset(
        for viewWidth: CGFloat,
        availableWidth: CGFloat,
        padding: UIEdgeInsets
    ) -> CGFloat {
        switch self {
        case .topLeading, .bottomLeading:
            return -(availableWidth - viewWidth) / 2 + padding.left
        case .topTrailing, .bottomTrailing:
            return (availableWidth - viewWidth) / 2 - padding.right
        }
    }

    func yOffset(
        for viewHeight: CGFloat,
        availableHeight: CGFloat,
        padding: UIEdgeInsets
    ) -> CGFloat {
        switch self {
        case .topTrailing, .topLeading:
            return -(availableHeight - viewHeight) / 2 + padding.top
        case .bottomLeading, .bottomTrailing:
            return (availableHeight - viewHeight) / 2 - padding.bottom
        }
    }

    func matchingFrame(in totalArea: CGRect) -> CGRect {
        let originX = totalArea.origin.x
        let originY = totalArea.origin.y
        let width = totalArea.width / 2
        let height = totalArea.height / 2
        let rectSize = CGSize(width: width, height: height)
        switch self {
        case .topLeading:
            return CGRect(
                origin: totalArea.origin,
                size: rectSize
            )
        case .topTrailing:
            return CGRect(
                origin: CGPoint(x: originX + width, y: originY),
                size: rectSize
            )
        case .bottomLeading:
            return CGRect(
                origin: CGPoint(x: originX, y: height + originY),
                size: rectSize
            )
        case .bottomTrailing:
            return CGRect(
                origin: CGPoint(x: originX + width, y: height + originY),
                size: rectSize
            )
        }
    }
}
