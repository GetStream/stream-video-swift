//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension AVAudioSession {
    struct Snapshot: Equatable, CustomStringConvertible {
        var category: AVAudioSession.Category
        var mode: AVAudioSession.Mode
        var categoryOptions: AVAudioSession.CategoryOptions
        var routeSharingPolicy: AVAudioSession.RouteSharingPolicy
        var availableModes: [AVAudioSession.Mode]
        var preferredInput: RTCAudioStore.StoreState.AudioRoute.Port?
        var renderingMode: String
        var prefersEchoCancelledInput: Bool
        var isEchoCancelledInputEnabled: Bool
        var isEchoCancelledInputAvailable: Bool
        var outputMuted: Bool
        var maximumOutputNumberOfChannels: Int
        var outputNumberOfChannels: Int
        var preferredOutputNumberOfChannels: Int

        var description: String {
            var result = "{"
            result += "category:\(category)"
            result += ", mode:\(mode)"
            result += ", categoryOptions:\(categoryOptions)"
            result += ", routeSharingPolicy:\(routeSharingPolicy)"
            result += ", availableModes:\(availableModes)"
            result += ", preferredInput:\(preferredInput)"
            result += ", renderingMode:\(renderingMode)"
            result += ", prefersEchoCancelledInput:\(prefersEchoCancelledInput)"
            result += ", isEchoCancelledInputEnabled:\(isEchoCancelledInputEnabled)"
            result += ", isEchoCancelledInputAvailable:\(isEchoCancelledInputAvailable)"
            result += ", outputMuted:\(outputMuted)"
            result += ", maximumOutputNumberOfChannels:\(maximumOutputNumberOfChannels)"
            result += ", outputNumberOfChannels:\(outputNumberOfChannels)"
            result += ", preferredOutputNumberOfChannels:\(preferredOutputNumberOfChannels)"
            result += " }"
            return result
        }

        init(_ source: AVAudioSession = .sharedInstance()) {
            self.category = source.category
            self.mode = source.mode
            self.categoryOptions = source.categoryOptions
            self.routeSharingPolicy = source.routeSharingPolicy
            self.availableModes = source.availableModes
            self.preferredInput = source.preferredInput.map { .init($0) } ?? nil
            if #available(iOS 17.2, *) { self.renderingMode = "\(source.renderingMode)" }
            else { self.renderingMode = "" }
            if #available(iOS 18.2, *) { self.prefersEchoCancelledInput = source.prefersEchoCancelledInput
            } else { self.prefersEchoCancelledInput = false }
            if #available(iOS 18.2, *) { self.isEchoCancelledInputEnabled = source.isEchoCancelledInputEnabled
            } else { self.isEchoCancelledInputEnabled = false }
            if #available(iOS 18.2, *) { self.isEchoCancelledInputAvailable = source.isEchoCancelledInputAvailable
            } else { self.isEchoCancelledInputAvailable = false }
            if #available(iOS 26.0, *) { self.outputMuted = source.isOutputMuted
            } else { self.outputMuted = false }
            self.maximumOutputNumberOfChannels = source.maximumOutputNumberOfChannels
            self.outputNumberOfChannels = source.outputNumberOfChannels
            self.preferredOutputNumberOfChannels = source.preferredOutputNumberOfChannels
        }
    }
}

final class AVAudioSessionObserver {

    var publisher: AnyPublisher<AVAudioSession.Snapshot, Never> { subject.eraseToAnyPublisher() }

    private let subject: CurrentValueSubject<AVAudioSession.Snapshot, Never> = .init(.init())
    private var cancellable: AnyCancellable?

    func startObserving() {
        cancellable = DefaultTimer
            .publish(every: 0.1)
            .sink { [weak self] _ in self?.subject.send(.init()) }
    }

    func stopObserving() {
        cancellable?.cancel()
        cancellable = nil
    }
}

extension AVAudioSessionObserver: InjectionKey {
    nonisolated(unsafe) static var currentValue: AVAudioSessionObserver = .init()
}

extension InjectedValues {
    var avAudioSessionObserver: AVAudioSessionObserver {
        get { InjectedValues[AVAudioSessionObserver.self] }
        set { InjectedValues[AVAudioSessionObserver.self] = newValue }
    }
}
