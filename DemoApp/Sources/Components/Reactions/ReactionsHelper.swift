//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamVideo
import SwiftUI

@MainActor
final class ReactionsHelper: ObservableObject {

    @Injected(\.streamVideo) var streamVideo

    var player: AVAudioPlayer?

    private var reactionsTask: Task<Void, Error>?
    private var callEndedNotificationObserver: Any?

    @Published var showFireworks = false
    @Published var availableReactions: [Reaction] = [
        .fireworks,
        .raiseHand,
        .lowerHand,
        .like,
        .dislike,
        .heart,
        .smile
    ]

    @Published var activeReactions: [String: [Reaction]] = [:]

    var call: Call? {
        didSet {
            subscribeToReactionEvents()
        }
    }

    init() {
        subscribeToCallStatusUpdates()
    }

    func send(reaction: Reaction) {
        Task {
            try await call?.sendReaction(
                type: reaction.id.rawValue,
                custom: [
                    "id": .string(reaction.id.rawValue),
                    "duration": .number(reaction.duration ?? 0),
                    "userSpecific": .bool(reaction.userSpecific),
                    "isReverted": .bool(shouldRevert(reaction: reaction))
                ],
                emojiCode: reaction.id.rawValue
            )
        }
    }

    func shouldRevert(reaction: Reaction) -> Bool {
        reaction.id == .raiseHand && activeReactions[streamVideo.user.id]?.first { $0.id == .raiseHand } != nil
    }

    func removeRaisedHand(from userId: String) {
        unregister(reaction: .raiseHand, for: userId)
    }

    private func subscribeToCallStatusUpdates() {
        callEndedNotificationObserver = NotificationCenter.default.addObserver(
            forName: .init(CallNotification.callEnded),
            object: nil,
            queue: nil
        ) { _ in Task { await MainActor.run { [weak self] in self?.handleCallEnded() } } }
    }

    private func subscribeToReactionEvents() {
        guard let call else {
            reactionsTask?.cancel()
            return
        }

        let callReactionEventsStream = call.subscribe(for: CallReactionEvent.self)

        reactionsTask = Task { [weak self] in
            for await event in callReactionEventsStream {
                guard
                    let reaction = self?.reaction(for: event)
                else {
                    continue
                }
                self?.handleReaction(reaction, from: event.reaction.user.toUser)
            }
            return
        }
    }

    private func reaction(for event: CallReactionEvent) -> Reaction? {
        guard let emojiCode = event.reaction.emojiCode else {
            return nil
        }

        if let availableReaction = availableReactions.first(where: { $0.id.rawValue == emojiCode }) {
            return availableReaction
        } else {
            return nil
        }
    }

    private func handleReaction(_ reaction: Reaction, from user: User) {
        switch reaction.id {
        case .fireworks:
            handleFireworksReaction(reaction, from: user)
        case .raiseHand:
            handleRaiseHandReaction(reaction, from: user)
        case .lowerHand:
            break
        case .like:
            handleSimpleReaction(reaction, from: user)
        case .dislike:
            handleSimpleReaction(reaction, from: user)
        case .heart:
            handleSimpleReaction(reaction, from: user)
        case .hello:
            handleSimpleReaction(reaction, from: user)
        case .smile:
            handleSimpleReaction(reaction, from: user)
        }
    }

    private func handleFireworksReaction(_ reaction: Reaction, from user: User) {
        guard reaction.id == .fireworks else { return }
        showFireworks = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.showFireworks = false
        }
    }

    private func handleRaiseHandReaction(_ reaction: Reaction, from user: User) {
        guard reaction.id == .raiseHand else { return }

        if activeReactions[user.id]?.first(where: { $0.id == .raiseHand }) != nil {
            unregister(reaction: .raiseHand, for: user.id)
        } else {
            register(reaction: .raiseHand, for: user.id)
        }
    }

    private func handleSimpleReaction(_ reaction: Reaction, from user: User) {
        register(reaction: reaction, for: user.id)

        let duration: Double = reaction.duration ?? 2.5
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.unregister(reaction: reaction, for: user.id)
        }
    }

    private func register(reaction: Reaction, for userId: String) {
        if activeReactions[userId] == nil {
            activeReactions[userId] = []
        }

        if activeReactions[userId]?.first?.id != reaction.id {
            activeReactions[userId]?.append(reaction)
        }
    }

    private func unregister(reaction: Reaction, for userId: String) {
        var found = false
        let userReactions = activeReactions[userId]?.filter { item in
            if !found, reaction.id == item.id {
                found = true
                return false
            } else {
                return true
            }
        }
        activeReactions[userId] = userReactions
    }

    private func handleCallEnded() {
        Task {
            await MainActor.run { [weak self] in
                self?.reactionsTask?.cancel()
                self?.reactionsTask = nil
            }
        }
    }
}
