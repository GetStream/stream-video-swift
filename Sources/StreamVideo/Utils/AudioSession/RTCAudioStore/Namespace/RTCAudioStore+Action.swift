//
//  RTCAudioStore+Action.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import AVFoundation

extension RTCAudioStore {

    /// Actions that drive the permissions state machine.
    ///
    /// Use these to update cached statuses or to trigger system prompts
    /// via middleware responsible for requesting permissions.
    public enum StoreAction: Sendable, Equatable, StoreActionBoxProtocol, CustomStringConvertible {

        enum StreamVideoAction: Equatable, Sendable, CustomStringConvertible {
            case setActiveCall(Call?)

            var description: String {
                switch self {
                case .setActiveCall(let call):
                    return ".setActiveCall(cId:\(call?.cId))"
                }
            }

            static func ==(lhs: StreamVideoAction, rhs: StreamVideoAction) -> Bool {
                switch (lhs, rhs) {
                case (let .setActiveCall(lhsCall), let .setActiveCall(rhsCall)):
                    return lhsCall === rhsCall
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

        case setAudioDeviceModule(AudioDeviceModule?)
        case setCurrentRoute(RTCAudioStore.StoreState.AudioRoute)

        case setPrefersHiFiPlayback(Bool)

        case avAudioSession(AVAudioSessionAction)
        case webRTCAudioSession(WebRTCAudioSessionAction)
        case callKit(CallKitAction)
        case streamVideo(StreamVideoAction)

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

            case .setAudioDeviceModule(let value):
                return ".setAudioDeviceModule(\(value))"

            case .setCurrentRoute(let value):
                return ".setCurrentRoute(\(value))"

            case .setPrefersHiFiPlayback(let value):
                return ".setPrefersHiFiPlayback(\(value))"

            case .avAudioSession(let value):
                return ".avAudioSession(\(value))"

            case .webRTCAudioSession(let value):
                return ".webRTCAudioSession(\(value))"

            case .callKit(let value):
                return ".callKit(\(value))"

            case .streamVideo(let value):
                return ".streamVideo(\(value))"
            }
        }
    }
}

