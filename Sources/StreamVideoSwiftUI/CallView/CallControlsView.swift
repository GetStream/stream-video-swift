//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallControlsView: View {
    
    @Injected(\.streamVideo) var streamVideo
        
    private let size: CGFloat = 50
    
    @ObservedObject var viewModel: CallViewModel
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(alignment: .top) {
            Spacer()
            
            if streamVideo.videoConfig.videoEnabled {
                Button(
                    action: {
                        viewModel.toggleCameraEnabled()
                    },
                    label: {
                        CallIconView(
                            icon: (viewModel.callSettings.videoOn ? images.videoTurnOn : images.videoTurnOff),
                            size: size,
                            iconStyle: (viewModel.callSettings.videoOn ? .primary : .transparent)
                        )
                    }
                )
                
                Spacer()
            }
            
            Button(
                action: {
                    viewModel.toggleMicrophoneEnabled()
                },
                label: {
                    CallIconView(
                        icon: (viewModel.callSettings.audioOn ? images.micTurnOn : images.micTurnOff),
                        size: size,
                        iconStyle: (viewModel.callSettings.audioOn ? .primary : .transparent)
                    )
                }
            )
            
            Spacer()
            
            if streamVideo.videoConfig.videoEnabled {
                Button(
                    action: {
                        viewModel.toggleCameraPosition()
                    },
                    label: {
                        CallIconView(
                            icon: images.toggleCamera,
                            size: size,
                            iconStyle: .primary
                        )
                    }
                )
                
                Spacer()
            }
            
            Button {
                viewModel.hangUp()
            } label: {
                images.hangup
                    .applyCallButtonStyle(
                        color: colors.hangUpIconColor,
                        size: size
                    )
            }
            
            Spacer()
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
