//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import struct StreamChat.ChannelId
import class StreamChat.ChatChannel
import class StreamChat.ChatChannelController
import protocol StreamChat.ChatChannelControllerDelegate
import class StreamChat.ChatClient
import enum StreamChat.EntityChange
import struct StreamChat.StreamAssetPropertyLoader
import class StreamChat.StreamAudioPlayer
import class StreamChat.StreamAudioRecorder
import class StreamChat.StreamAudioSessionConfigurator
import struct StreamChat.Token
import StreamChatSwiftUI
import StreamVideo
import StreamVideoSwiftUI

/// In the DemoApp chat is only reachable while a call is active, and during a
/// call StreamVideo owns the shared `AVAudioSession`. StreamChat's default
/// configurator deactivates that session (`setActive(false)`) when its audio
/// player or recorder stops — e.g. `ChatChannelViewModel.deinit` stops the
/// audio player when the chat sheet is presented/dismissed — which tears down
/// the call's audio I/O and mutes both mic and speakers (IOS-1821). Keep chat
/// away from the session entirely: playback/recording of voice messages still
/// works against the already-active call session.
/// ponytail: unconditional no-op; if chat ever becomes reachable outside a
/// call, gate these on `AppState.shared.activeCall == nil` instead.
final class DemoChatAudioSessionConfigurator: StreamAudioSessionConfigurator, @unchecked Sendable {
    override func activateRecordingSession() throws {}
    override func deactivateRecordingSession() throws {}
    override func activatePlaybackSession() throws {}
    override func deactivatePlaybackSession() throws {}
}

struct DemoChatAdapter {

    let chatClient: ChatClient
    let streamChatUI: StreamChat

    @MainActor
    init(userId: String, userName: String, imageURL: URL?, token: String) {
        let chatClient = ChatClient(config: .init(apiKeyString: AppState.shared.apiKey))

        self.chatClient = chatClient

        let utils = StreamChatSwiftUI.Utils()
        let audioSessionConfigurator = DemoChatAudioSessionConfigurator()
        utils.audioPlayerBuilder = {
            StreamAudioPlayer(
                assetPropertyLoader: StreamAssetPropertyLoader(),
                audioSessionConfigurator: audioSessionConfigurator
            )
        }
        utils.audioRecorderBuilder = {
            StreamAudioRecorder(
                configuration: .default,
                audioSessionConfigurator: audioSessionConfigurator
            )
        }
        self.streamChatUI = .init(chatClient: chatClient, utils: utils)

        InjectionKey.currentValue = self

        chatClient.connectUser(
            userInfo: .init(
                id: userId,
                name: userName,
                imageURL: imageURL
            )
        ) { completionHandler in
            Task {
                do {
                    let userToken = try await AuthenticationProvider.fetchToken(for: userId)
                    let token = try Token(rawValue: userToken.rawValue)
                    completionHandler(.success(token))
                } catch {
                    completionHandler(.failure(error))
                }
            }
        }
    }
}

extension DemoChatAdapter {
    /// Returns the current value for the `StreamVideo` instance.
    struct InjectionKey: StreamChatSwiftUI.InjectionKey {
        nonisolated(unsafe) static var currentValue: DemoChatAdapter?
    }
}

extension StreamChatSwiftUI.InjectedValues {
    /// Provides access to the `StreamVideo` instance in the views and view models.
    var chatWrapper: DemoChatAdapter? {
        get {
            Self[DemoChatAdapter.InjectionKey.self]
        }
        set {
            Self[DemoChatAdapter.InjectionKey.self] = newValue
        }
    }
}
