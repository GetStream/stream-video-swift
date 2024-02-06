//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import EffectsLibrary
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallView<ViewFactory: DemoAppViewFactory>: View {

    @Injected(\.appearance) var appearance
    @Injected(\.chatViewModel) var chatViewModel

    var microphoneChecker: MicrophoneChecker

    @ObservedObject var appState: AppState = .shared
    @ObservedObject var viewModel: CallViewModel
    @ObservedObject var reactionsHelper: ReactionsHelper = AppState.shared.reactionsHelper
    @StateObject var snapshotViewModel: DemoSnapshotViewModel

    @State var mutedIndicatorShown = false

    private let viewFactory: ViewFactory

    init(
        viewFactory: ViewFactory,
        microphoneChecker: MicrophoneChecker,
        viewModel: CallViewModel
    ) {
        self.viewFactory = viewFactory
        self.microphoneChecker = microphoneChecker
        self.viewModel = viewModel
        _snapshotViewModel = .init(wrappedValue: .init(viewModel))
    }

    var body: some View {
        viewFactory
            .makeInnerCallView(viewModel: viewModel)
            .onReceive(viewModel.callSettingsPublisher) { _ in
                updateMicrophoneChecker()
            }
            .onReceive(microphoneChecker.decibelsPublisher, perform: { values in
                guard !viewModel.callSettings.audioOn else { return }
                for value in values {
                    if (value > -50 && value < 0) && !mutedIndicatorShown {
                        mutedIndicatorShown = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            mutedIndicatorShown = false
                        }
                        return
                    }
                }
            })
            .overlay(
                mutedIndicatorShown ?
                    VStack {
                        Spacer()
                        Text("You are muted.")
                            .padding(8)
                            .background(Color(UIColor.systemBackground))
                            .foregroundColor(appearance.colors.text)
                            .cornerRadius(16)
                            .padding()
                    }
                    : nil
            )
            .overlay(
                ZStack {
                    reactionsHelper.showFireworks
                        ? FireworksView(config: FireworksConfig(intensity: .high, lifetime: .long, initialVelocity: .fast))
                        : nil
                }
            )
            .onDisappear {
                microphoneChecker.stopListening()
            }
            .onAppear {
                updateMicrophoneChecker()
            }
            .presentsMoreControls(viewModel: viewModel)
            .chat(viewModel: viewModel, chatViewModel: chatViewModel)
            .toastView(toast: $snapshotViewModel.toast)
    }

    private func updateMicrophoneChecker() {
        if viewModel.call != nil, !viewModel.callSettings.audioOn {
            microphoneChecker.startListening()
        } else {
            microphoneChecker.stopListening()
        }
    }
}

@MainActor
final class DemoSnapshotViewModel: ObservableObject {

    private let viewModel: CallViewModel
    private var snapshotEventsTask: Task<Void, Never>?

    @Published var toast: Toast?

    init(_ viewModel: CallViewModel) {
        self.viewModel = viewModel
        subscribeForSnapshotEvents()
    }

    private func subscribeForSnapshotEvents() {
        guard let call = viewModel.call else {
            snapshotEventsTask?.cancel()
            snapshotEventsTask = nil
            return
        }

        snapshotEventsTask = Task {
            for await event in call.subscribe(for: CustomVideoEvent.self) {
                guard
                    let imageBase64Data = event.custom["snapshot"]?.stringValue,
                    let imageData = Data(base64Encoded: imageBase64Data),
                    let image = UIImage(data: imageData)
                else {
                    return
                }

                toast = .init(
                    style: .custom(
                        baseStyle: .success,
                        icon: AnyView(
                            Image(uiImage: image)
                                .resizable()
                                .frame(maxWidth: 30, maxHeight: 30)
                                .aspectRatio(contentMode: .fit)
                                .clipShape(Circle())
                        )
                    ),
                    message: "Snapshot captured!"
                )
            }
        }
    }
}
