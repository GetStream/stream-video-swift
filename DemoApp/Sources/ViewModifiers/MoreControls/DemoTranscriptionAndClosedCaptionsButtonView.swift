//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoTranscriptionAndClosedCaptionsButtonView: View {

    @Injected(\.colors) private var colors
    @ObservedObject var viewModel: CallViewModel

    @State private var isTranscriptionAvailable = false
    @State private var isTranscribing = false

    @State private var areClosedCaptionsAvailable = false
    @State private var isCaptioning = false

    private var availableLanguages: [TranscriptionSettings.Language] = TranscriptionSettings
        .Language
        .allCases
        .filter { $0 != .unknown && $0 != .auto }

    init(viewModel: CallViewModel) {
        self.viewModel = viewModel

        isTranscriptionAvailable = (viewModel.call?.state.settings?.transcription.mode ?? .disabled) != .disabled
            && viewModel.call?.currentUserHasCapability(.startTranscriptionCall) == true
            && viewModel.call?.currentUserHasCapability(.stopTranscriptionCall) == true
        isTranscribing = viewModel.call?.state.transcribing == true

        areClosedCaptionsAvailable = (viewModel.call?.state.settings?.transcription.closedCaptionMode ?? .disabled) != .disabled
            && viewModel.call?.currentUserHasCapability(.startClosedCaptionsCall) == true
            && viewModel.call?.currentUserHasCapability(.stopClosedCaptionsCall) == true
        isCaptioning = viewModel.call?.state.captioning == true
    }

    var body: some View {
        Group {
            if isTranscriptionAvailable || areClosedCaptionsAvailable {
                Menu {
                    if isTranscriptionAvailable {
                        transcriptionContentView
                    }

                    if areClosedCaptionsAvailable {
                        Menu {
                            closedCaptionsContentView
                            closedCaptionsLanguageContentView
                        } label: {
                            Text("Closed Captions")
                        }
                    }
                } label: {
                    Label {
                        Text("Transcription & Closed Captions")
                    } icon: {
                        Image(systemName: "captions.bubble")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .frame(height: 40)
                    .foregroundColor(colors.white)
                    .background(Color(colors.participantBackground))
                    .clipShape(Capsule())
                }
                .onReceive(viewModel.call?.state.$transcribing) { isTranscribing = $0 }
                .onReceive(viewModel.call?.state.$captioning) { isCaptioning = $0 }
            }
        }
        .onReceive(viewModel.call?.state.$settings) {
            if let mode = $0?.transcription.mode {
                isTranscriptionAvailable = mode != .disabled
            } else {
                isTranscriptionAvailable = false
            }

            if let mode = $0?.transcription.closedCaptionMode {
                areClosedCaptionsAvailable = mode != .disabled
            } else {
                areClosedCaptionsAvailable = false
            }
        }
    }

    private var closedCaptionsLanguage: TranscriptionSettings.Language {
        viewModel.call?.state.settings?.transcription.language ?? .auto
    }

    @ViewBuilder
    private var transcriptionContentView: some View {
        Menu {
            selectableView(
                TranscriptionSettings.Mode.available,
                isEqualHandler: { _ in isTranscribing }
            ) { execute { try await viewModel.call?.startTranscription() } }

            selectableView(
                TranscriptionSettings.Mode.disabled,
                isEqualHandler: { _ in !isTranscribing }
            ) { execute { try await viewModel.call?.stopTranscription() } }
        } label: {
            Label {
                Text("Transcriptions")
            } icon: {
                Image(systemName: isTranscribing ? "captions.bubble.fill" : "captions.bubble")
            }
        }
    }

    @ViewBuilder
    private var closedCaptionsContentView: some View {
        Menu {
            selectableView(
                TranscriptionSettings.ClosedCaptionMode.available,
                isEqualHandler: { _ in isCaptioning && AppEnvironment.closedCaptionsIntegration == .enabled }
            ) { execute {
                try await viewModel.call?.startClosedCaptions()
            }
            }

            selectableView(
                TranscriptionSettings.ClosedCaptionMode.disabled,
                isEqualHandler: { _ in !isCaptioning && AppEnvironment.closedCaptionsIntegration == .enabled }
            ) { execute { try await viewModel.call?.stopClosedCaptions() } }

            Divider()

            locallyDisabledView
        } label: {
            Label {
                Text("Mode")
            } icon: {
                Image(
                    systemName: isCaptioning && AppEnvironment
                        .closedCaptionsIntegration == .enabled ? "captions.bubble.fill" : "captions.bubble"
                )
            }
        }
    }

    @ViewBuilder
    private var locallyDisabledView: some View {
        Button {
            switch AppEnvironment.closedCaptionsIntegration {
            case .enabled:
                AppEnvironment.closedCaptionsIntegration = .disabled
            case .disabled:
                AppEnvironment.closedCaptionsIntegration = .enabled
            }
        } label: {
            switch AppEnvironment.closedCaptionsIntegration {
            case .enabled:
                Text("Deactivate locally")
            case .disabled:
                Text("Remove local deactivation")
            }
        }
    }

    @ViewBuilder
    private var closedCaptionsLanguageContentView: some View {
        Menu {
            selectableView("Unknown") { _ in
                viewModel
                    .call?
                    .state
                    .settings?
                    .transcription
                    .language == .unknown
            } action: {
                execute {
                    try await viewModel.call?.stopClosedCaptions()
                    try await viewModel.call?.startClosedCaptions(.init(language: nil))
                }
            }

            Divider()

            ForEach(availableLanguages, id: \.self) { language in
                selectableView(
                    language,
                    isEqualHandler: {
                        viewModel
                            .call?
                            .state
                            .settings?
                            .transcription
                            .language == $0
                    }
                ) { execute {
                    try await viewModel.call?.stopClosedCaptions()
                    try await viewModel.call?.startClosedCaptions(.init(language: language.rawValue))
                } }
            }
        } label: {
            Text("Language: \(closedCaptionsLanguage.description)")
        }
    }

    @ViewBuilder
    private func selectableView<T: Equatable & CustomStringConvertible>(
        _ value: T,
        isEqualHandler: (T) -> Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            if isEqualHandler(value) {
                Label {
                    Text(value.description)
                } icon: {
                    Image(systemName: "checkmark")
                }
            } else {
                Text(value.description)
            }
        }
    }

    private func execute(_ action: @escaping () async throws -> Void) {
        Task {
            do {
                try await action()
            } catch {
                log.error(error)
            }
        }
    }
}
