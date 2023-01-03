//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CornerDragableView<Content: View>: View {
    @State var callViewPlacement = CallViewPlacement.topTrailing

    @State private var dragAmount = CGSize.zero

    private var scaleFactorX: CGFloat
    private var scaleFactorY: CGFloat

    var content: Content
    var proxy: GeometryProxy
    var onTap: () -> Void

    public init(
        scaleFactorX: CGFloat = 0.33,
        scaleFactorY: CGFloat = 0.33,
        content: Content,
        proxy: GeometryProxy,
        onTap: @escaping () -> Void
    ) {
        self.scaleFactorX = scaleFactorX
        self.scaleFactorY = scaleFactorY
        self.content = content
        self.proxy = proxy
        self.onTap = onTap
    }

    public var body: some View {
        content
            .onTapGesture {
                withAnimation {
                    onTap()
                }
            }
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
            .cornerRadius(16)
            .transition(.scale)
            .scaleEffect(x: scaleFactorX, y: scaleFactorY)
            .offset(
                x: callViewPlacement.xOffset(
                    for: proxy.size.width * scaleFactorX,
                    availableWidth: proxy.size.width
                ) + dragAmount.width,
                y: callViewPlacement.yOffset(
                    for: proxy.size.height * scaleFactorY,
                    availableHeight: proxy.size.height
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
        for placement in availablePlacements {
            let frame = placement.matchingFrame(in: rect)
            if frame.contains(location) {
                return placement
            }
        }
        return .topTrailing
    }
}

public enum CallViewPlacement {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing

    func xOffset(
        for viewWidth: CGFloat,
        availableWidth: CGFloat
    ) -> CGFloat {
        switch self {
        case .topLeading, .bottomLeading:
            return -(availableWidth - viewWidth) / 2
        case .topTrailing, .bottomTrailing:
            return (availableWidth - viewWidth) / 2
        }
    }

    func yOffset(
        for viewHeight: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        switch self {
        case .topTrailing, .topLeading:
            return -(availableHeight - viewHeight) / 2
        case .bottomLeading, .bottomTrailing:
            return (availableHeight - viewHeight) / 2
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
