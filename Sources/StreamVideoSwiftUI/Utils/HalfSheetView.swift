//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI
import StreamVideo

struct HalfSheetView<Content: View>: View {
    @Injected(\.colors) var colors

    @Binding var isPresented: Bool
    let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(maxHeight: .infinity)

            DraggableSheetView(isPresented: $isPresented) {
                content()
            }
        }
        .alignedToReadableContentGuide()
        .animation(.spring(duration: 0.3))
        .opacity(isPresented ? 1 : 0)
        .edgesIgnoringSafeArea(.all)
    }
}

struct DraggableSheetView<Content: View>: View {

    @Injected(\.colors) var colors

    var isPresented: Binding<Bool>
    var content: () -> Content
    var dismissalFraction: CGFloat = 0.33 // we need to swipe just 1/3 of the total height.

    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                DragHandleView()
                    .background(Color(colors.callBackground)) // Give the view "volume" so the DragGesture is effective from it's whole width.
                    .padding(.vertical, 6)
                    .padding(.horizontal, 24) // Avoid collision with rounded corners.
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = max(0, value.translation.height)
                            }
                            .onEnded { value in
                                if value.translation.height > proxy.size.height * dismissalFraction {
                                    dragOffset = proxy.size.height
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        isPresented.wrappedValue = false
                                        dragOffset = 0
                                    }
                                } else {
                                    dragOffset = 0
                                }
                            }
                    )
                content()
                    .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
            .cornerRadius(
                24,
                corners: [.topLeft, .topRight],
                backgroundColor: Color(colors.callBackground)
            )
            .offset(y: isPresented.wrappedValue ? dragOffset : proxy.size.height / 2)
        }
    }
}

public struct DragHandleView: View {

    public init() {}

    public var body: some View {
        VStack(alignment: .center) {
            Color.white.opacity(0.3)
                .frame(width: 44, height: 5)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
    }
}

extension View {

    @ViewBuilder
    public func halfSheet<Content>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View where Content : View {
        if #available (iOS 16.0, *) {
            sheet(isPresented: isPresented, onDismiss: onDismiss) {
                content()
                    .padding(.vertical)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        } else {
            overlay(
                HalfSheetView(isPresented: isPresented) {
                    content()
                }
            )
        }
    }
}