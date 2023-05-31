//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

private var streamVideoUI: StreamVideoUI?

@main
struct StreamVideoSwiftUIAppClip: App {

    // MARK: - State properties

    @ObservedObject var appState = AppState.shared

    // MARK: - Lifecycle

    init() {
        LogConfig.level = .debug
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.userState == .loggedIn {
                    AppClipCallView(callId: appState.deeplinkInfo.callId)
                } else {
                    Text("Loading ...")
                }
            }
            .onOpenURL { handle(url: $0) }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { $0.webpageURL.map { url in handle(url: url) } }
        }
    }

    // MARK: - Private Helpers

    private func handle(url: URL) {
        let (deeplinkInfo, _) = DeeplinkAdapter(baseURL: Config.baseURL).handle(url: url)
        guard
            deeplinkInfo != .empty
        else {
            return
        }

        let user = {
            guard let currentUser = appState.currentUser, currentUser.id == currentUser.name else {
                return User.guest(String(UUID().uuidString.prefix(8)))
            }
            return currentUser
        }()

        Task {
            await MainActor.run {
                Task {
                    let streamVideo = try await StreamVideo(
                        apiKey: Config.apiKey,
                        user: user
                    )
                    appState.deeplinkInfo = deeplinkInfo
                    appState.currentUser = user
                    appState.userState = .loggedIn
                    appState.streamVideo = streamVideo
                    let utils = Utils(userListProvider: MockUserListProvider())
                    streamVideoUI = StreamVideoUI(streamVideo: streamVideo, utils: utils)
                    appState.connectUser()
                }
            }
        }
    }
}
