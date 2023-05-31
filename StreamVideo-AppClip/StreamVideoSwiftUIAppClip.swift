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

        Task {
            let user = User.guest(String(UUID().uuidString.prefix(8)))
            AppState.shared.deeplinkInfo = .empty
            AppState.shared.currentUser = user
            AppState.shared.userState = .loggedIn
            let streamVideo = try await StreamVideo(apiKey: Config.apiKey, user: user)
            AppState.shared.streamVideo = streamVideo
            let utils = Utils(userListProvider: MockUserListProvider())
            streamVideoUI = StreamVideoUI(streamVideo: streamVideo, utils: utils)
            AppState.shared.connectUser()
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if appState.streamVideo != nil {
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
        appState.deeplinkInfo = deeplinkInfo
    }
}
