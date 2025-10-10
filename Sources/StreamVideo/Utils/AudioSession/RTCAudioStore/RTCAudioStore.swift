//
//  RTCAudioStore.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/10/25.
//

import Foundation
import StreamWebRTC
import Combine

final class RTCAudioStore: @unchecked Sendable {

    private let store: Store<Namespace>

    static let shared = RTCAudioStore()

    var state: Namespace.State { store.state }
    private let audioSession: RTCAudioSession

    init(
        audioSession: RTCAudioSession = .sharedInstance()
    ) {
        self.audioSession = audioSession
        self.store = Namespace.store(
            initialState: .init(
                isActive: false,
                isInterrupted: false,
                shouldRecord: false,
                isRecording: false,
                isMicrophoneMuted: false,
                hasRecordingPermission: false,
                audioDeviceModule: nil,
                currentRoute: .init(audioSession.currentRoute),
                audioSessionConfiguration: .init(
                    category: .soloAmbient,
                    mode: .default,
                    options: [],
                    overrideOutputAudioPort: .none
                ),
                webRTCAudioSessionConfiguration: .init(
                    isAudioEnabled: false,
                    useManualAudio: false,
                    prefersNoInterruptionsFromSystemAlerts: false
                )
            ),
            reducers: Namespace.reducers(audioSession: audioSession),
            middleware: Namespace.middleware(audioSession: audioSession),
        )

        store.dispatch([
            .normal(.webRTCAudioSession(.setPrefersNoInterruptionsFromSystemAlerts(true))),
            .normal(.webRTCAudioSession(.setUseManualAudio(true))),
            .normal(.webRTCAudioSession(.setAudioEnabled(false))),
        ])
    }

    // MARK: - Observation

    func publisher<V: Equatable>(
        _ keyPath: KeyPath<Namespace.State, V>
    ) -> AnyPublisher<V, Never> {
        store.publisher(keyPath)
    }

    // MARK: - Dispatch

    @discardableResult
    func dispatch(
        _ actions: [StoreActionBox<Namespace.Action>],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        store.dispatch(
            actions,
            file: file,
            function: function,
            line: line
        )
    }

    @discardableResult
    func dispatch(
        _ actions: [Namespace.Action],
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        store.dispatch(
            actions,
            file: file,
            function: function,
            line: line
        )
    }

    @discardableResult
    func dispatch(
        _ action: Namespace.Action,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) -> StoreTask<Namespace> {
        store.dispatch( 
            [action],
            file: file,
            function: function,
            line: line
        )
    }
}

extension RTCAudioStore: InjectionKey {
    nonisolated(unsafe) static var currentValue: RTCAudioStore = .shared
}

extension InjectedValues {
    var audioStore: RTCAudioStore {
        get { Self[RTCAudioStore.self] }
        set { Self[RTCAudioStore.self] = newValue }
    }
}
