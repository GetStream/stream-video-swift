//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Monitors the device battery state and exposes the latest readings through
/// the shared store pipeline.
final class BatteryStore: CustomStringConvertible, @unchecked Sendable {

    var state: Namespace.State { store.state }

    var description: String {
        var result = "Battery {"
        result += " isMonitoring:\(store.state.isMonitoringEnabled)"
        result += " state:\(store.state.state)"
        result += " level:\(store.state.level)"
        result += " }"
        return result
    }

    private let store: Store<Namespace>
    private let disposableBag = DisposableBag()

    init(
        store: Store<Namespace> = Namespace.store(
            initialState: .init(
                isMonitoringEnabled: false,
                state: .unknown,
                level: 0
            )
        )
    ) {
        self.store = store

        self.store.dispatch(.setMonitoringEnabled(true))

        #if canImport(UIKit)
        self.store
            .publisher(\.isMonitoringEnabled)
            .filter { $0 }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .map { _ in
                MainActor.assumeIsolated {
                    (
                        UIDevice.current.batteryState,
                        UIDevice.current.batteryLevel
                    )
                }
            }
            .sink { [weak self] stateAndLevel in
                let (state, level) = stateAndLevel
                self?.store.dispatch([
                    .setState(.init(state)),
                    .setLevel(level)
                ])
            }
            .store(in: disposableBag)
        #endif
    }

    func publisher<V: Equatable>(
        _ keyPath: KeyPath<Namespace.State, V>
    ) -> AnyPublisher<V, Never> {
        store.publisher(keyPath)
    }

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
}

extension BatteryStore: Encodable {
    private enum CodingKeys: String, CodingKey {
        case isMonitoringEnabled
        case state
        case level
    }

    /// Encodes a snapshot of the store's observable state.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let state = store.state
        try container.encode(
            state.isMonitoringEnabled,
            forKey: .isMonitoringEnabled
        )
        try container.encode(state.state, forKey: .state)
        try container.encode(state.level, forKey: .level)
    }
}

extension BatteryStore: InjectionKey {
    /// The default recorder instance used when no custom recorder is
    /// provided.
    nonisolated(unsafe) static var currentValue: BatteryStore = .init()
}

extension InjectedValues {
    var battery: BatteryStore {
        get {
            Self[BatteryStore.self]
        }
        set {
            Self[BatteryStore.self] = newValue
        }
    }
}
