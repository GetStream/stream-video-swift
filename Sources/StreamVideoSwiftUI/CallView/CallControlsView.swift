//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying call controls such as video toggle, microphone toggle, and participants list button.
public struct CallControlsView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel

    /// Initializes the call controls view with a view model.
    /// - Parameter viewModel: The view model for the call controls.
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

/// A view displaying the video toggle button for a call.
public struct VideoIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    /// Initializes the video icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the video icon.
    ///   - size: The size of the video icon (default is 44).
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

/// A view displaying the microphone toggle button for a call.
public struct MicrophoneIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    /// Initializes the microphone icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the microphone icon.
    ///   - size: The size of the microphone icon (default is 44).
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

/// A view displaying the toggle camera position button for a call.
public struct ToggleCameraIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    /// Initializes the toggle camera icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the toggle camera icon.
    ///   - size: The size of the toggle camera icon (default is 44).
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

/// A view displaying the hang-up button for a call.
public struct HangUpIconView: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    /// Initializes the hang-up icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the hang-up icon.
    ///   - size: The size of the hang-up icon (default is 44).
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

/// A view displaying the audio output toggle button for a call.
public struct AudioOutputIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    /// Initializes the audio output icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the audio output icon.
    ///   - size: The size of the audio output icon (default is 44).
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

/// A view displaying the speaker toggle button for a call.
public struct SpeakerIconView: View {

    @Injected(\.images) var images

    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat

    /// Initializes the speaker icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the speaker icon.
    ///   - size: The size of the speaker icon (default is 44).
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
