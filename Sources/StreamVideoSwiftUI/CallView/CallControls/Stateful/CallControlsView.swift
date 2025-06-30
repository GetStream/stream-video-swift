//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI

/// A view displaying call controls such as video toggle, microphone toggle, and participants list button.
public struct CallControlsView: View {

    var viewModel: CallViewModel

    /// Initializes the call controls view with a view model.
    /// - Parameter viewModel: The view model for the call controls.
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        HStack {
            // TODO: Make sure that controls are showing for outgoing calls too
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

    weak var call: Call?
    var size: CGFloat
    var capabilityPublisher: AnyPublisher<Bool, Never>?
    var actionHandler: () -> Void

    @State var hasRequiredCapability: Bool

    /// Initializes the video icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the video icon.
    ///   - size: The size of the video icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        hasRequiredCapability = viewModel.call?.state.ownCapabilities.contains(.sendVideo) ?? false
        capabilityPublisher = viewModel.call?.state.$ownCapabilities.compactMap { $0.contains(.sendVideo) }.eraseToAnyPublisher()
        actionHandler = { [weak viewModel] in viewModel?.toggleCameraEnabled() }
    }

    public var body: some View {
        if hasRequiredCapability {
            StatelessVideoIconView(
                call: call,
                actionHandler: actionHandler
            )
        }
    }
}

/// A view displaying the microphone toggle button for a call.
public struct MicrophoneIconView: View {

    weak var call: Call?
    var size: CGFloat
    var capabilityPublisher: AnyPublisher<Bool, Never>?
    var actionHandler: () -> Void

    @State var hasRequiredCapability: Bool

    /// Initializes the microphone icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the microphone icon.
    ///   - size: The size of the microphone icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        hasRequiredCapability = viewModel.call?.state.ownCapabilities.contains(.sendAudio) ?? false
        capabilityPublisher = viewModel.call?.state.$ownCapabilities.compactMap { $0.contains(.sendAudio) }.eraseToAnyPublisher()
        actionHandler = { [weak viewModel] in viewModel?.toggleMicrophoneEnabled() }
    }

    public var body: some View {
        if hasRequiredCapability {
            StatelessMicrophoneIconView(
                call: call,
                actionHandler: actionHandler
            )
        }
    }
}

/// A view displaying the toggle camera position button for a call.
public struct ToggleCameraIconView: View {

    @Injected(\.images) var images

    weak var call: Call?
    var size: CGFloat
    var capabilityPublisher: AnyPublisher<Bool, Never>?
    var actionHandler: () -> Void

    @State var hasRequiredCapability: Bool

    /// Initializes the toggle camera icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the toggle camera icon.
    ///   - size: The size of the toggle camera icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        hasRequiredCapability = viewModel.call?.state.ownCapabilities.contains(.sendVideo) ?? false
        capabilityPublisher = viewModel.call?.state.$ownCapabilities.compactMap { $0.contains(.sendVideo) }.eraseToAnyPublisher()
        actionHandler = { [weak viewModel] in viewModel?.toggleCameraPosition() }
    }

    public var body: some View {
        if let call {
            content
                .id(call.cId + "_" + "\(type(of: self))")
                .onReceive(capabilityPublisher) { hasRequiredCapability = $0 }
        }
    }

    @ViewBuilder
    var content: some View {
        if hasRequiredCapability {
            StatelessToggleCameraIconView(
                call: call,
                actionHandler: actionHandler
            )
        }
    }
}

/// A view displaying the hang-up button for a call.
public struct HangUpIconView: View {

    @Injected(\.images) var images
    @Injected(\.colors) var colors

    var viewModel: CallViewModel
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

    weak var call: Call?
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the audio output icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the audio output icon.
    ///   - size: The size of the audio output icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        actionHandler = { [weak viewModel] in viewModel?.toggleAudioOutput() }
    }

    public var body: some View {
        StatelessAudioOutputIconView(
            call: call,
            actionHandler: actionHandler
        )
    }
}

/// A view displaying the speaker toggle button for a call.
public struct SpeakerIconView: View {

    weak var call: Call?
    var size: CGFloat
    var actionHandler: () -> Void

    /// Initializes the speaker icon view with a view model and optional size.
    /// - Parameters:
    ///   - viewModel: The view model for the speaker icon.
    ///   - size: The size of the speaker icon (default is 44).
    public init(viewModel: CallViewModel, size: CGFloat = 44) {
        call = viewModel.call
        self.size = size
        actionHandler = { [weak viewModel] in viewModel?.toggleSpeaker() }
    }

    public var body: some View {
        StatelessSpeakerIconView(
            call: call,
            actionHandler: actionHandler
        )
    }
}
