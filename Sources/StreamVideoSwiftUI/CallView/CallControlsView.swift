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
            
            VideoIconView(viewModel: viewModel)
            
            Spacer()
            
            MicrophoneIconView(viewModel: viewModel)
            
            Spacer()
            
            ToggleCameraIconView(viewModel: viewModel)
            
            Spacer()

            HangUpIconView(viewModel: viewModel)
            
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

public struct VideoIconView: View {
            
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
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
        .accessibility(identifier: "cameraToggle")
        .streamAccessibility(value: viewModel.callSettings.videoOn ? "1" : "0")
    }
}

public struct MicrophoneIconView: View {
    
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
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
        .accessibility(identifier: "microphoneToggle")
        .streamAccessibility(value: viewModel.callSettings.audioOn ? "1" : "0")
    }
}

public struct ToggleCameraIconView: View {
    
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
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
        .accessibility(identifier: "cameraPositionToggle")
        .streamAccessibility(value: viewModel.callSettings.cameraPosition == .front ? "1" : "0")
    }
}

public struct HangUpIconView: View {
    
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
            viewModel.hangUp()
        } label: {
            images.hangup
                .applyCallButtonStyle(
                    color: colors.hangUpIconColor,
                    size: size
                )
        }
        .accessibility(identifier: "hangUp")
    }
}

public struct AudioOutputIconView: View {
    
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        Button(
            action: {
                viewModel.toggleAudioOutput()
            },
            label: {
                CallIconView(
                    icon: (viewModel.callSettings.audioOutputOn ? images.speakerOn : images.speakerOff),
                    size: size,
                    iconStyle: (viewModel.callSettings.audioOutputOn ? .primary : .transparent)
                )
            }
        )
    }
    
}

public struct SpeakerIconView: View {
    
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        Button(
            action: {
                viewModel.toggleSpeaker()
            },
            label: {
                CallIconView(
                    icon: (viewModel.callSettings.speakerOn ? images.speakerOn : images.speakerOff),
                    size: size,
                    iconStyle: (viewModel.callSettings.speakerOn ? .primary : .transparent)
                )
            }
        )
    }
    
}
