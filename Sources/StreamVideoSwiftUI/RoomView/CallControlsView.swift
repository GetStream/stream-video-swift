//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

public struct CallControlsView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        CallControlsContainer(
            callSettings: viewModel.callSettings,
            onToggleCamera: viewModel.toggleCameraEnabled,
            onToggleMicrophone: viewModel.toggleMicrophoneEnabled,
            onToggleCameraPosition: viewModel.toggleCameraPosition,
            onHangUp: viewModel.leaveCall
        )
        .frame(height: 200)
    }
}

struct CallControlsContainer: View {
    
    @ObservedObject var callSettings: CallSettings
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    var onToggleCamera: @MainActor() -> Void
    var onToggleMicrophone: @MainActor() -> Void
    var onToggleCameraPosition: @MainActor() -> Void
    var onHangUp: @MainActor() -> Void
    
    public var body: some View {
        if callSettings.videoOn {
            VideoControlsView(
                callSettings: callSettings,
                onToggleCamera: onToggleCamera,
                onToggleMicrophone: onToggleMicrophone,
                onToggleCameraPosition: onToggleCameraPosition,
                onHangUp: onHangUp
            )
        } else {
            AudioControlsView(
                callSettings: callSettings,
                onToggleCamera: onToggleCamera,
                onToggleMicrophone: onToggleMicrophone,
                onToggleCameraPosition: onToggleCameraPosition,
                onHangUp: onHangUp
            )
        }
    }
}

struct VideoControlsView: View {
    
    @ObservedObject var callSettings: CallSettings
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    private let size: CGFloat = 56
    
    var onToggleCamera: @MainActor() -> Void
    var onToggleMicrophone: @MainActor() -> Void
    var onToggleCameraPosition: @MainActor() -> Void
    var onHangUp: @MainActor() -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Button {
                onHangUp()
            } label: {
                images.hangup
                    .applyCallButtonStyle(
                        color: colors.hangUpIconColor,
                        size: 80
                    )
            }
            .padding(.all)
            
            HStack {
                Spacer()
                
                Button(
                    action: {
                        onToggleMicrophone()
                    },
                    label: {
                        CallIconView(
                            icon: (callSettings.audioOn ? images.micTurnOff : images.micTurnOn),
                            size: size,
                            iconStyle: .transparent
                        )
                    }
                )
                                                
                Spacer()
                                
                Button(
                    action: {
                        onToggleCameraPosition()
                    },
                    label: {
                        CallIconView(
                            icon: images.toggleCamera,
                            size: size,
                            iconStyle: .transparent
                        )
                    }
                )

                Spacer()
                                
                Button(
                    action: {
                        onToggleCamera()
                    },
                    label: {
                        CallIconView(
                            icon: (callSettings.videoOn ? images.videoTurnOff : images.videoTurnOn),
                            size: size,
                            iconStyle: .transparent
                        )
                    }
                )
                
                Spacer()
            }
        }
    }
}

struct AudioControlsView: View {
    
    @ObservedObject var callSettings: CallSettings
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    var onToggleCamera: @MainActor() -> Void
    var onToggleMicrophone: @MainActor() -> Void
    var onToggleCameraPosition: @MainActor() -> Void
    var onHangUp: @MainActor() -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                
                Button(
                    action: {
                        onToggleMicrophone()
                    },
                    label: {
                        CallIconView(
                            icon: (callSettings.audioOn ? images.micTurnOff : images.micTurnOn)
                        )
                    }
                )
                                                
                Spacer()
                                
                Button(
                    action: {
                        onToggleCameraPosition()
                    },
                    label: {
                        CallIconView(icon: images.toggleCamera)
                    }
                )

                Spacer()
                                
                Button(
                    action: {
                        onToggleCamera()
                    },
                    label: {
                        CallIconView(
                            icon: (callSettings.videoOn ? images.videoTurnOff : images.videoTurnOn),
                            iconStyle: .transparent
                        )
                    }
                )
                
                Spacer()
            }
            
            Button {
                onHangUp()
            } label: {
                images.hangup
                    .applyCallButtonStyle(
                        color: colors.hangUpIconColor,
                        size: 80
                    )
            }
            .padding(.all)
        }
    }
}
