//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view that allows dragging a content view to specific corners based on user gestures.
public struct CornerDraggableView<Content: View>: View {
    @State var callViewPlacement = CallViewPlacement.topTrailing
    @State private var dragAmount = CGSize.zero

    private var scaleFactorX: CGFloat
    private var scaleFactorY: CGFloat
    private var availableFrame: CGRect
    private var padding: UIEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)

    var content: (CGRect) -> Content
    var proxy: GeometryProxy
    var onTap: () -> Void

    /// Initializes a corner draggable view with the specified parameters.
    /// - Parameters:
    ///   - scaleFactorX: The scale factor for the width of the draggable area.
    ///   - scaleFactorY: The scale factor for the height of the draggable area.
    ///   - content: A closure that provides the content view with a given frame.
    ///   - proxy: The geometry proxy representing the enclosing view's geometry.
    ///   - onTap: A closure that is invoked when the view is tapped.
    public init(
        scaleFactorX: CGFloat = 0.33,
        scaleFactorY: CGFloat = 0.33,
        content: @escaping (CGRect) -> Content,
        proxy: GeometryProxy,
        onTap: @escaping () -> Void
    ) {
        self.scaleFactorX = scaleFactorX
        self.scaleFactorY = scaleFactorY
        self.content = content
        self.proxy = proxy
        self.onTap = onTap

        let proxyFrame = proxy.frame(in: .local)
        availableFrame = .init(
            origin: .zero,
            size: .init(
                width: proxyFrame.width * scaleFactorX,
                height: proxyFrame.height * scaleFactorY
            )
        )
    }

    public var body: some View {
        content(availableFrame)
            .overlay(
                // SwiftUI seems to remove any interaction of views that not
                // getting rendered (e.g. an empty GeometryReader, a VStack
                // with a Spacer, an EmptyView, a Color.clear or a Shape
                // with clear fill). If we use a simple button here then the
                // interaction happening is slower because than what we have now.
                Color.black.opacity(0.01)
                    // This is to avoid conflicts with buttons on the top and bottom
                    // part of the participant view.
                    .padding(.vertical, 30)
                    .onTapGesture { onTap() }
            )
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged {
                        self.dragAmount = CGSize(width: $0.translation.width, height: $0.translation.height)
                    }
                    .onEnded { gestureState in
                        withAnimation {
                            self.callViewPlacement = self.checkCallPlacement(
                                for: gestureState.location,
                                in: proxy.frame(in: .global)
                            )
                            self.dragAmount = .zero
                        }
                    }
            )
            .transition(.scale)
            .frame(width: availableFrame.width, height: availableFrame.height)
            .offset(
                x: callViewPlacement.xOffset(
                    for: availableFrame.width,
                    availableWidth: proxy.size.width,
                    padding: padding
                ) + dragAmount.width,
                y: callViewPlacement.yOffset(
                    for: availableFrame.height,
                    availableHeight: proxy.size.height,
                    padding: padding
                ) + dragAmount.height
            )
            .padding()
            .background(Color.clear)
    }

    private func checkCallPlacement(for location: CGPoint, in rect: CGRect) -> CallViewPlacement {
        let availablePlacements: [CallViewPlacement] = [
            .topTrailing,
            .topLeading,
            .bottomTrailing,
            .bottomLeading
        ]

        var closestPlacement: CallViewPlacement?
        var minDistance: CGFloat?

        for placement in availablePlacements {
            let frame = placement.matchingFrame(in: rect)
            if frame.contains(location) {
                return placement
            }

            // Calculate the center of the frame
            let centerX = frame.origin.x + frame.size.width / 2
            let centerY = frame.origin.y + frame.size.height / 2
            let centerPoint = CGPoint(x: centerX, y: centerY)

            // Calculate the Euclidean distance to the location
            let distance = sqrt(pow(centerPoint.x - location.x, 2) + pow(centerPoint.y - location.y, 2))

            // Check if this is the closest placement so far
            if minDistance == nil {
                minDistance = distance
                closestPlacement = placement
            } else if let _minDistance = minDistance, distance < _minDistance {
                minDistance = distance
                closestPlacement = placement
            }
        }

        return closestPlacement ?? .topTrailing // default to .topTrailing if for some reason no placement was closer
    }
}

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
