//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallControlsView: View {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            VideoIconView(viewModel: viewModel)
            MicrophoneIconView(viewModel: viewModel)

            Spacer()

            if viewModel.callingState == .inCall {
                ParticipantsListButton(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
    }
}

public struct VideoIconView: View {
            
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
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
                    iconStyle: (viewModel.callSettings.videoOn ? .transparent : .disabled)
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
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
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
                    iconStyle: (viewModel.callSettings.audioOn ? .transparent : .disabled)
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
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
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
                    iconStyle: .secondary
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
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        Button {
            viewModel.hangUp()
        } label: {
            CallIconView(
                icon: images.hangup,
                size: size,
                iconStyle: .destructive
            )
        }
        .accessibility(identifier: "hangUp")
    }
}

public struct AudioOutputIconView: View {
    
    @Injected(\.images) var images
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
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
    
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
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
