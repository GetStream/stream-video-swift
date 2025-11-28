//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import Foundation

extension AVAudioSession {
    /// Captures a stable view of the session so state changes can be diffed
    /// outside of the AVAudioSession API, which otherwise exposes mutable
    /// objects.
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
        var maximumOutputNumberOfChannels: Int
        var outputNumberOfChannels: Int
        var preferredOutputNumberOfChannels: Int

        /// Produces a compact string payload that is easy to log when
        /// diagnosing audio route transitions.
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
            result += ", maximumOutputNumberOfChannels:\(maximumOutputNumberOfChannels)"
            result += ", outputNumberOfChannels:\(outputNumberOfChannels)"
            result += ", preferredOutputNumberOfChannels:\(preferredOutputNumberOfChannels)"
            result += " }"
            return result
        }

        /// Builds a new snapshot by pulling the latest values from the shared
        /// AVAudioSession instance.
        init(_ source: AVAudioSession = .sharedInstance()) {
            self.category = source.category
            self.mode = source.mode
            self.categoryOptions = source.categoryOptions
            self.routeSharingPolicy = source.routeSharingPolicy
            self.availableModes = source.availableModes
            self.preferredInput = source.preferredInput.map { .init($0) } ?? nil
            #if compiler(>=6.0)
            if #available(iOS 17.2, *) { self.renderingMode = "\(source.renderingMode)" }
            else { self.renderingMode = "" }
            #else
            self.renderingMode = ""
            #endif

            #if compiler(>=6.0)
            if #available(iOS 18.2, *) { self.prefersEchoCancelledInput = source.prefersEchoCancelledInput
            } else { self.prefersEchoCancelledInput = false }
            #else
            self.prefersEchoCancelledInput = false
            #endif

            #if compiler(>=6.0)
            if #available(iOS 18.2, *) { self.isEchoCancelledInputEnabled = source.isEchoCancelledInputEnabled
            } else { self.isEchoCancelledInputEnabled = false }
            #else
            self.isEchoCancelledInputEnabled = false
            #endif

            #if compiler(>=6.0)
            if #available(iOS 18.2, *) { self.isEchoCancelledInputAvailable = source.isEchoCancelledInputAvailable
            } else { self.isEchoCancelledInputAvailable = false }
            #else
            self.isEchoCancelledInputAvailable = false
            #endif
            self.maximumOutputNumberOfChannels = source.maximumOutputNumberOfChannels
            self.outputNumberOfChannels = source.outputNumberOfChannels
            self.preferredOutputNumberOfChannels = source.preferredOutputNumberOfChannels
        }
    }
}

/// Polls the shared AVAudioSession on a timer so stores can react using Combine.
final class AVAudioSessionObserver {

    var publisher: AnyPublisher<AVAudioSession.Snapshot, Never> { subject.eraseToAnyPublisher() }

    private let subject: CurrentValueSubject<AVAudioSession.Snapshot, Never> = .init(.init())
    private var cancellable: AnyCancellable?

    /// Starts emitting snapshots roughly every 100ms, which is fast enough to
    /// catch rapid route transitions without adding noticeable overhead.
    func startObserving() {
        cancellable = DefaultTimer
            .publish(every: 0.1)
            .sink { [weak self] _ in self?.subject.send(.init()) }
    }

    /// Cancels the observation timer and stops sending snapshot updates.
    func stopObserving() {
        cancellable?.cancel()
        cancellable = nil
    }
}

extension AVAudioSessionObserver: InjectionKey {
    nonisolated(unsafe) static var currentValue: AVAudioSessionObserver = .init()
}

extension InjectedValues {
    /// Injects the audio session observer so effects can subscribe without
    /// hard-coding their own polling logic.
    var avAudioSessionObserver: AVAudioSessionObserver {
        get { InjectedValues[AVAudioSessionObserver.self] }
        set { InjectedValues[AVAudioSessionObserver.self] = newValue }
    }
}
