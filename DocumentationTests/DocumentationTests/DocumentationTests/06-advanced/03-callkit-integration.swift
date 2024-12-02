//
//  03-callkit-integration.swift
//  DocumentationTests
//
//  Created by Ilias Pavlidakis on 29/1/24.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import Combine
import Intents

@MainActor
fileprivate func content() {
    container {
        @Injected(\.callKitAdapter) var callKitAdapter

        callKitAdapter.availabilityPolicy = .always
    }

    container {
        @Injected(\.callKitAdapter) var callKitAdapter

        callKitAdapter.availabilityPolicy = .regionBased
    }

    container {
        struct MyCustomAvailabilityPolicy: CallKitAvailabilityPolicyProtocol {
            var isAvailable: Bool {
                // Example: Enable CallKit only for premium users
                return UserManager.currentUser?.isPremium == true
            }
        }

        @Injected(\.callKitAdapter) var callKitAdapter
        callKitAdapter.availabilityPolicy = .custom(MyCustomAvailabilityPolicy())
    }

    container {
        @Injected(\.callKitAdapter) var callKitAdapter

        let streamVideo = StreamVideo(
            apiKey: apiKey,
            user: user,
            token: token,
            tokenProvider: { _ in }
        )
        callKitAdapter.streamVideo = streamVideo
    }

    container {
        struct MyCustomView: View {
            @Injected(\.callKitAdapter) var callKitAdapter

            var body: some View {
                EmptyView() // Our content goes here.
                    .onAppear {
                        callKitAdapter.registerForIncomingCalls()

                        // Here we can also inject an image (e.g. a logo) that will be used
                        // by CallKit's UI.
                        callKitAdapter.iconTemplateImageData = UIImage(named: "logo")?.pngData()
                    }
            }
        }
    }

    container {
        final class MyCustomViewController: UIViewController {
            @Injected(\.callKitAdapter) var callKitAdapter

            override func viewDidLoad() {
                super.viewDidLoad()
                callKitAdapter.registerForIncomingCalls()
                callKitAdapter.iconTemplateImageData = UIImage(named: "logo")?.pngData()
            }
        }
    }

    container {
        struct MyCustomView: View {
            @Injected(\.streamVideo) var streamVideo
            @Injected(\.callKitAdapter) var callKitAdapter
            @Injected(\.callKitPushNotificationAdapter) var callKitPushNotificationAdapter

            var body: some View {
                Button {
                    let deviceToken = callKitPushNotificationAdapter.deviceToken
                    if !deviceToken.isEmpty {
                        Task {
                            // Unregister the device token
                            try await streamVideo.deleteDevice(id: deviceToken)
                        }
                    }
                    // Perform any other logout operations
                    callKitAdapter.streamVideo = nil
                } label: {
                    Text("Logout")
                }
            }
        }
    }

    container {
        @Injected(\.streamVideo) var streamVideo
        @Injected(\.callKitPushNotificationAdapter) var callKitPushNotificationAdapter
        var lastVoIPToken: String?
        var voIPTokenObservationCancellable: AnyCancellable?

        voIPTokenObservationCancellable = callKitPushNotificationAdapter.$deviceToken.sink { [streamVideo] updatedDeviceToken in
            Task {
                do {
                    if let lastVoIPToken, !lastVoIPToken.isEmpty {
                        try await streamVideo.deleteDevice(id: lastVoIPToken)
                    }
                    if !updatedDeviceToken.isEmpty {
                        try await streamVideo.setVoipDevice(id: updatedDeviceToken)
                    }
                    lastVoIPToken = updatedDeviceToken
                } catch {
                    print(error)
                }
            }
        }
    }

    container {
        class IntentHandler: INExtension, INStartCallIntentHandling {
            override func handler(for intent: INIntent) -> Any {
                return self
            }

            func handle(intent: INStartCallIntent, completion: @escaping (INStartCallIntentResponse) -> Void) {
                let userActivity = NSUserActivity(activityType: NSStringFromClass(INStartCallIntent.self))
                let response = INStartCallIntentResponse(code: .continueInApp, userActivity: userActivity)

                completion(response)
            }
        }
    }

    container {
        struct MyCustomView: View {
            var name: String = ""
            var body: some View {
                HomeView(viewModel: viewModel)
                    .modifier(CallModifier(viewModel: viewModel))
                    .onContinueUserActivity(
                        NSStringFromClass(INStartCallIntent.self),
                        perform: {
                            userActivity in
                            let interaction = userActivity.interaction
                            if let callIntent = interaction?.intent as? INStartCallIntent {

                                let contact = callIntent.contacts?.first

                                guard let name = contact?.personHandle?.value else { return }
                                viewModel.startCall(
                                    callType: .default,
                                    callId: UUID().uuidString,
                                    members: [.init(userId: name)],
                                    ring: true
                                )
                            }
                        }
                    )
            }
        }
    }

    container {
        @Injected(\.callKitAdapter) var callKitAdapter

        callKitAdapter.callSettings = CallSettings(audioOn: true, videoOn: false)
    }

    container {
        @Injected(\.callKitService) var callKitService

        // Setting the `supportsVideo` property to `true` will
        // make the subtitle's format be: `<Application's name> Video`
        callKitService.supportsVideo = true

        // Setting the `supportsVideo` property to `false` will
        // make the subtitle's format be: `<Application's name> Audio`
        callKitService.supportsVideo = false
    }
}
