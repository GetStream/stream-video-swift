//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import SwiftUI

/// A view displaying call controls such as video toggle, microphone toggle, and participants list button.
public struct CallControlsView: View {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.colors) var colors

    @ObservedObject var viewModel: CallViewModel
    @State var ownCapabilities: [OwnCapability]

    /// Initializes the call controls view with a view model.
    /// - Parameter viewModel: The view model for the call controls.
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
        ownCapabilities = viewModel.call?.state.ownCapabilities ?? []
    }

    public var body: some View {
        HStack {
            if ownCapabilities.contains(.sendVideo) == true {
                VideoIconView(viewModel: viewModel)
            }
            if ownCapabilities.contains(.sendAudio) == true {
                MicrophoneIconView(viewModel: viewModel)
            }

            Spacer()

            if viewModel.callingState == .inCall {
                ParticipantsListButton(viewModel: viewModel)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .onReceive(call?.state.$ownCapabilities.receive(on: DispatchQueue.main)) { ownCapabilities = $0 }
    }

    private var call: Call? {
        switch viewModel.callingState {
        case .incoming, .outgoing:
            return streamVideo.state.ringingCall
        default:
            return viewModel.call
        }
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
        StatelessVideoIconView(call: viewModel.call) { [weak viewModel] in
            viewModel?.toggleCameraEnabled()
        }
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
        StatelessMicrophoneIconView(call: viewModel.call) { [weak viewModel] in
            viewModel?.toggleMicrophoneEnabled()
        }
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
        StatelessToggleCameraIconView(call: viewModel.call) { [weak viewModel] in
            viewModel?.toggleCameraPosition()
        }
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
        StatelessHangUpIconView(call: viewModel.call) { [weak viewModel] in
            viewModel?.hangUp()
        }
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
        StatelessAudioOutputIconView(call: viewModel.call) { [weak viewModel] in
            viewModel?.toggleAudioOutput()
        }
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
        StatelessSpeakerIconView(call: viewModel.call) { [weak viewModel] in
            viewModel?.toggleSpeaker()
        }
    }
}
