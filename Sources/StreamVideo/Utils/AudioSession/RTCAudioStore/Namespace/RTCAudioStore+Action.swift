//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension RTCAudioStore {

    /// Actions that drive the permissions state machine.
    ///
    /// Use these to update cached statuses or to trigger system prompts
    /// via middleware responsible for requesting permissions.
    enum StoreAction: Sendable, Equatable, StoreActionBoxProtocol, CustomStringConvertible {

        enum StereoAction: Equatable, Sendable, CustomStringConvertible {
            case setPlayoutAvailable(Bool)
            case setPlayoutEnabled(Bool)

            var description: String {
                switch self {
                case let .setPlayoutAvailable(value):
                    return "setPlayoutAvailable(\(value))"
                case let .setPlayoutEnabled(value):
                    return "setPlayoutEnabled(\(value))"
                }
            }

            static func == (lhs: StereoAction, rhs: StereoAction) -> Bool {
                switch (lhs, rhs) {
                case (let .setPlayoutAvailable(lhsValue), let .setPlayoutAvailable(rhsValue)):
                    return lhsValue == rhsValue

                case (let .setPlayoutEnabled(lhsValue), let .setPlayoutEnabled(rhsValue)):
                    return lhsValue == rhsValue

                default:
                    return false
                }
            }
        }

        enum AVAudioSessionAction: Equatable, Sendable, CustomStringConvertible {
            case setCategory(AVAudioSession.Category)
            case setMode(AVAudioSession.Mode)
            case setCategoryOptions(AVAudioSession.CategoryOptions)

            case setCategoryAndMode(AVAudioSession.Category, mode: AVAudioSession.Mode)
            case setCategoryAndCategoryOptions(
                AVAudioSession.Category,
                categoryOptions: AVAudioSession.CategoryOptions
            )
            case setModeAndCategoryOptions(
                AVAudioSession.Mode,
                categoryOptions: AVAudioSession.CategoryOptions
            )
            case setCategoryAndModeAndCategoryOptions(
                AVAudioSession.Category,
                mode: AVAudioSession.Mode,
                categoryOptions: AVAudioSession.CategoryOptions
            )
            case setOverrideOutputAudioPort(AVAudioSession.PortOverride)

            var description: String {
                switch self {
                case .setCategory(let category):
                    return ".setCategory(\(category))"

                case .setMode(let mode):
                    return ".setMode(\(mode))"

                case .setCategoryOptions(let categoryOptions):
                    return ".setCategoryOptions(\(categoryOptions))"

                case .setCategoryAndMode(let category, let mode):
                    return ".setCategoryAndMode(\(category), mode:\(mode))"

                case .setCategoryAndCategoryOptions(let category, let categoryOptions):
                    return ".setCategoryAndCategoryOptions(\(category), categoryOptions:\(categoryOptions))"

                case .setModeAndCategoryOptions(let mode, let categoryOptions):
                    return ".setModeAndCategoryOptions(\(mode), categoryOptions:\(categoryOptions))"

                case .setCategoryAndModeAndCategoryOptions(let category, let mode, let categoryOptions):
                    return ".setModeAndCategoryOptions(\(category), mode:\(mode), categoryOptions:\(categoryOptions))"

                case .setOverrideOutputAudioPort(let portOverride):
                    return ".setOverrideOutputAudioPort(\(portOverride))"
                }
            }
        }

        enum WebRTCAudioSessionAction: Equatable, Sendable, CustomStringConvertible {
            case setAudioEnabled(Bool)
            case setUseManualAudio(Bool)
            case setPrefersNoInterruptionsFromSystemAlerts(Bool)

            var description: String {
                switch self {
                case .setAudioEnabled(let value):
                    return ".setAudioEnabled(\(value))"

                case .setUseManualAudio(let value):
                    return ".setUseManualAudio(\(value))"

                case .setPrefersNoInterruptionsFromSystemAlerts(let value):
                    return ".setPrefersNoInterruptionsFromSystemAlerts(\(value))"
                }
            }
        }

        enum CallKitAction: Equatable, Sendable, CustomStringConvertible {
            case activate(AVAudioSession)
            case deactivate(AVAudioSession)

            var description: String {
                switch self {
                case .activate(let value):
                    return ".activate(\(value))"

                case .deactivate(let value):
                    return ".deactivate(\(value))"
                }
            }
        }

        case setActive(Bool)
        case setInterrupted(Bool)
        case setShouldRecord(Bool)
        case setRecording(Bool)
        case setMicrophoneMuted(Bool)
        case setHasRecordingPermission(Bool)
        case setSpeakerOutputChannels(Int)
        case setReceiverOutputChannels(Int)

        case setAudioDeviceModule(AudioDeviceModule?)
        case setCurrentRoute(RTCAudioStore.StoreState.AudioRoute)
        case setRouteTransitionState(RTCAudioStore.StoreState.RouteTransitionState)

        case avAudioSession(AVAudioSessionAction)
        case webRTCAudioSession(WebRTCAudioSessionAction)
        case callKit(CallKitAction)
        case stereo(StereoAction)

        var description: String {
            switch self {
            case .setActive(let value):
                return ".setActive(\(value))"

            case .setInterrupted(let value):
                return ".setInterrupted(\(value))"

            case .setShouldRecord(let value):
                return ".setShouldRecord(\(value))"

            case .setRecording(let value):
                return ".setRecording(\(value))"

            case .setMicrophoneMuted(let value):
                return ".setMicrophoneMuted(\(value))"

            case .setHasRecordingPermission(let value):
                return ".setHasRecordingPermission(\(value))"

            case .setSpeakerOutputChannels(let value):
                return ".setSpeakerOutputChannels(\(value))"

            case .setReceiverOutputChannels(let value):
                return ".setReceiverOutputChannels(\(value))"

            case .setAudioDeviceModule(let value):
                return ".setAudioDeviceModule(\(value))"

            case .setRouteTransitionState(let value):
                return ".setRouteTransitionState(\(value))"

            case .setCurrentRoute(let value):
                return ".setCurrentRoute(\(value))"

            case .avAudioSession(let value):
                return ".avAudioSession(\(value))"

            case .webRTCAudioSession(let value):
                return ".webRTCAudioSession(\(value))"

            case .callKit(let value):
                return ".callKit(\(value))"

            case .stereo(let value):
                return ".stereo(\(value))"
            }
        }
    }
}
