//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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

extension TranscriptionSettings.Mode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .autoOn:
            return "auto-on"
        case .available:
            return "Available"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
}

extension TranscriptionSettings.ClosedCaptionMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .autoOn:
            return "auto-on"
        case .available:
            return "Available"
        case .disabled:
            return "Disabled"
        case .unknown:
            return "Unknown"
        }
    }
}

extension TranscriptionSettings.Language: CustomStringConvertible, CaseIterable {
    public var description: String {
        switch self {
        case .ar: return "Arabic"
        case .auto: return "Auto"
        case .ca: return "Catalan"
        case .cs: return "Czech"
        case .da: return "Danish"
        case .de: return "German"
        case .el: return "Greek"
        case .en: return "English"
        case .es: return "Spanish"
        case .fi: return "Finnish"
        case .fr: return "French"
        case .he: return "Hebrew"
        case .hi: return "Hindi"
        case .hr: return "Croatian"
        case .hu: return "Hungarian"
        case .id: return "Indonesian"
        case .it: return "Italian"
        case .ja: return "Japanese"
        case .ko: return "Korean"
        case .ms: return "Malay"
        case .nl: return "Dutch"
        case .no: return "Norwegian"
        case .pl: return "Polish"
        case .pt: return "Portuguese"
        case .ro: return "Romanian"
        case .ru: return "Russian"
        case .sv: return "Swedish"
        case .ta: return "Tamil"
        case .th: return "Thai"
        case .tl: return "Tagalog"
        case .tr: return "Turkish"
        case .uk: return "Ukrainian"
        case .zh: return "Chinese"
        case .unknown:
            return "Unknown"
        }
    }
}
