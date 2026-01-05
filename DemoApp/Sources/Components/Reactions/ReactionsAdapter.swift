//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation
import StreamVideo
import SwiftUI

final class ReactionsAdapter: ObservableObject, @unchecked Sendable {

    var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    var player: AVAudioPlayer?

    private var callEndedNotificationObserver: Any?
    private var activeCallUpdated: AnyCancellable?
    private let disposableBag = DisposableBag()
    private var call: Call? { didSet { subscribeToReactionEvents() } }

    @Published var showFireworks = false
    @Published var availableReactions: [Reaction] = [
        .like,
        .fireworks,
        .dislike,
        .heart,
        .smile,
        .raiseHand,
        .lowerHand
    ]

    @Published var activeReactions: [String: [Reaction]] = [:]

    // MARK: - Actions

    func send(reaction: Reaction) {
        guard let call else { return }
        Task {
            do {
                try await call.sendReaction(
                    type: reaction.id.rawValue,
                    custom: [
                        "id": .string(reaction.id.rawValue),
                        "duration": .number(reaction.duration ?? 0),
                        "userSpecific": .bool(reaction.userSpecific),
                        "isReverted": .bool(shouldRevert(reaction: reaction))
                    ],
                    emojiCode: reaction.id.rawValue
                )
            } catch {
                log.error(error)
            }
        }
    }

    func shouldRevert(reaction: Reaction) -> Bool {
        guard let streamVideo else { return false }
        return reaction.id == .raiseHand
            && activeReactions[streamVideo.user.id]?.first { $0.id == .raiseHand } != nil
    }

    func removeRaisedHand(from userId: String) {
        unregister(reaction: .raiseHand, for: userId)
    }

    // MARK: - Private API

    private func didUpdate(_ streamVideo: StreamVideo?) {

        activeCallUpdated?.cancel()
        activeCallUpdated = nil
        callEndedNotificationObserver = nil

        guard let streamVideo else { return }

        activeCallUpdated = streamVideo
            .state
            .$activeCall
            .sink { [weak self] in self?.call = $0 }

        callEndedNotificationObserver = NotificationCenter.default.addObserver(
            forName: .init(CallNotification.callEnded),
            object: nil,
            queue: nil
        ) { _ in Task { @MainActor [weak self] in self?.handleCallEnded() } }
    }

    private func subscribeToReactionEvents() {
        guard let call else {
            disposableBag.removeAll()
            return
        }

        call
            .eventPublisher(for: CallReactionEvent.self)
            .sinkTask(storeIn: disposableBag) { [weak self] event in
                guard
                    let reaction = self?.reaction(for: event)
                else {
                    return
                }
                self?.handleReaction(reaction, from: event.reaction.user.toUser)
                log.debug("\(event.reaction.user.name ?? event.reaction.user.id) reacted with reaction:\(reaction.id)")
            }
            .store(in: disposableBag)
    }

    private func reaction(for event: CallReactionEvent) -> Reaction? {
        guard let emojiCode = event.reaction.emojiCode else {
            log
                .warning(
                    "\(event.reaction.user.name ?? event.reaction.user.id) reacted with unsupported emojiCode:\(event.reaction.emojiCode ?? "n/a")"
                )
            return nil
        }

        if let availableReaction = availableReactions.first(where: { $0.id.rawValue == emojiCode }) {
            return availableReaction
        } else {
            log
                .warning(
                    "\(event.reaction.user.name ?? event.reaction.user.id) reacted with unsupported emojiCode:\(event.reaction.emojiCode ?? "n/a")"
                )
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
        Task { @MainActor in
            if activeReactions[userId] == nil {
                activeReactions[userId] = []
            }

            if activeReactions[userId]?.first?.id != reaction.id {
                activeReactions[userId]?.append(reaction)
            }
        }
    }

    private func unregister(reaction: Reaction, for userId: String) {
        Task { @MainActor in
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
    }

    private func handleCallEnded() {
        disposableBag.removeAll()
    }
}

extension ReactionsAdapter: InjectionKey {
    nonisolated(unsafe) static var currentValue: ReactionsAdapter = .init()
}

extension InjectedValues {
    var reactionsAdapter: ReactionsAdapter {
        get { Self[ReactionsAdapter.self] }
        set { Self[ReactionsAdapter.self] = newValue }
    }
}
