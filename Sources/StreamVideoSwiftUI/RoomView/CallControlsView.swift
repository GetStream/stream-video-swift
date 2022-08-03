//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

public struct CallControlsView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    public var body: some View {
        HStack {
            Spacer()
            
            Button(action: {
                viewModel.toggleCameraEnabled()
            },
            label: {
                (viewModel.cameraTrackState.isPublished ? images.videoTurnOff : images.videoTurnOn)
                    .applyCallButtonStyle(color: .black, backgroundType: .none)
            })
            .disabled(viewModel.cameraTrackState.isBusy)
            
            Spacer()
            
            Button(action: {
                viewModel.toggleMicrophoneEnabled()
            },
            label: {
                (viewModel.microphoneTrackState.isPublished ? images.micTurnOff : images.micTurnOn)
                    .applyCallButtonStyle(color: .black)
            })
            .disabled(viewModel.microphoneTrackState.isBusy)
            
            Spacer()
            
            Button(action: {
                viewModel.toggleCameraPosition()
            },
            label: {
                images.toggleCamera
                    .applyCallButtonStyle(color: .black, backgroundType: .rectangle)
            })
            
            Spacer()
            
            Button {
                viewModel.leaveCall()
            } label: {
                images.hangup
                    .applyCallButtonStyle(color: colors.hangUpIconColor)
            }
            .padding(.all, 8)
            
            Spacer()
        }
        .background(
            Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)
        )
    }
}
