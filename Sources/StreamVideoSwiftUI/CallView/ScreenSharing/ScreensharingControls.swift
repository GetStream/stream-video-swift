//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct ScreenshareIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        Button {
            viewModel.startScreensharing(type: .inApp)
        } label: {
            CallIconView(
                icon: Image(systemName: "square.and.arrow.up.circle.fill"),
                size: size,
                iconStyle: (viewModel.call?.state.isCurrentUserScreensharing == false ? .primary : .transparent)
            )
        }
    }
}

@available(iOS 14.0, *)
public struct BroadcastIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: CallViewModel
    @StateObject var broadcastObserver = BroadcastObserver()
    let size: CGFloat
    let iconStyle = CallIconStyle.primary
    let preferredExtension: String
    let iconSize: CGFloat = 50
    
    public init(
        viewModel: CallViewModel,
        preferredExtension: String,
        size: CGFloat = 50
    ) {
        self.viewModel = viewModel
        self.preferredExtension = preferredExtension
        self.size = size
    }
    
    public var body: some View {
        ZStack(alignment: .center) {
            Circle().fill(
                iconStyle.backgroundColor.opacity(iconStyle.opacity)
            )
            BroadcastPickerView(
                preferredExtension: preferredExtension,
                size: iconSize
            )
            .frame(width: iconSize, height: iconSize)
            .offset(x: -5, y: -4)
            .foregroundColor(iconStyle.foregroundColor)
        }
        .frame(width: size, height: size)
        .modifier(ShadowModifier())
        .onChange(of: broadcastObserver.broadcastState, perform: { newValue in
            if newValue == .started {
                viewModel.startScreensharing(type: .broadcast)
            } else if newValue == .finished {
                viewModel.stopScreensharing()
                broadcastObserver.broadcastState = .notStarted
            }
        })
        .disabled(isDisabled)
        .onAppear {
            broadcastObserver.observe()
        }
    }
    
    private var isDisabled: Bool {
        guard viewModel.call?.state.screenSharingSession != nil else {
            return false
        }
        return viewModel.call?.state.isCurrentUserScreensharing == false
    }
}
