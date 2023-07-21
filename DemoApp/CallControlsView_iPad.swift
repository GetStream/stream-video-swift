//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct CallControlsView_iPad: View {
    
    @Injected(\.streamVideo) var streamVideo
        
    private let size: CGFloat = 50
    
    @ObservedObject var viewModel: CallViewModel
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        EqualSpacingHStack {
            [
                VideoIconView(viewModel: viewModel).asAnyView,
                MicrophoneIconView(viewModel: viewModel).asAnyView,
                ToggleCameraIconView(viewModel: viewModel).asAnyView,
                ScreenshareIconView(viewModel: viewModel).asAnyView,
                HangUpIconView(viewModel: viewModel).asAnyView
            ]
        }
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .background(
            colors.callControlsBackground
                .edgesIgnoringSafeArea(.all)
        )
        .overlay(
            VStack {
                colors.callControlsBackground
                    .frame(height: 30)
                    .cornerRadius(24)
                Spacer()
            }
            .offset(y: -15)
        )
    }
}

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
            if viewModel.call?.state.isCurrentUserScreensharing == true {
                viewModel.stopScreensharing()
            } else {
                viewModel.startScreensharing()
            }
        } label: {
            CallIconView(
                icon: Image(systemName: "square.and.arrow.up.circle.fill"),
                size: size,
                iconStyle: (viewModel.call?.state.isCurrentUserScreensharing == false ? .primary : .transparent)
            )
        }
    }
}

struct EqualSpacingHStack: View {
    
    var views: () -> [AnyView]
    
    var body: some View {
        HStack(alignment: .top) {
            ForEach(0..<views().count, id:\.self) { index in
                Spacer()
                views()[index]
                Spacer()
            }
        }
    }
    
}

extension View {
    
    var asAnyView: AnyView {
        AnyView(self)
    }
    
}
