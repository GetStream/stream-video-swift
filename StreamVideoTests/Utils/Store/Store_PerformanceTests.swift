//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

/// Performance tests for Store to measure throughput and latency.
///
/// These tests measure:
/// - Action dispatch throughput
/// - State update latency
/// - Memory usage under load
/// - Publisher performance
final class Store_PerformanceTests: XCTestCase, @unchecked Sendable {
    
    private var store: Store<PerformanceTestNamespace>!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        store = PerformanceTestNamespace.store(initialState: .initial)
    }
    
    override func tearDown() {
        cancellables = nil
        store = nil
        super.tearDown()
    }
    
    // MARK: - Throughput Tests
    
    /// Measures dispatch throughput for simple actions.
    func test_measureDispatchThroughput() {
        let iterations = 10000
        
        measure(
            baseline: .init(1.1, stringTransformer: { String(format: "%.4fs", $0) })
        ) {
            for _ in 0..<iterations {
                store.dispatch(.increment)
            }
            
            // Wait for completion
            let expectation = XCTestExpectation(description: "Actions processed")
            
            Task {
                await fulfillment(timeout: 10) {
                    self.store.state.counter == iterations
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
            
            // Reset for next iteration
            store.dispatch(.reset)
        }
    }
    
    /// Measures synchronous dispatch latency.
    func test_measureSyncDispatchLatency() {
        measure(
            baseline: .init(local: 0.005, ci: 0.01, stringTransformer: { String(format: "%.4fs", $0) })
        ) {
            let expectation = XCTestExpectation(description: "Sync dispatch")
            
            Task {
                
                for i in 0..<100 {
                    try? await store.dispatch(.setValue(i)).result()
                }
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
    
    /// Measures dispatch throughput with delays.
    func test_measureDispatchWithDelaysThroughput() {
        let iterations = 100
        
        measure(
            baseline: .init(1.1, stringTransformer: { String(format: "%.4fs", $0) })
        ) {
            for i in 0..<iterations {
                // Small delay to simulate debouncing
                let delay = StoreDelay(
                    before: 0.001
                )
                store.dispatch(.delayed(.setValue(i), delay: delay))
            }
            
            // Wait for completion
            let expectation = XCTestExpectation(description: "Actions processed")
            
            Task {
                await fulfillment(timeout: 10) {
                    self.store.state.value == iterations - 1
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
        }
    }
    
    // MARK: - Publisher Performance Tests
    
    /// Measures publisher notification performance.
    func test_measurePublisherPerformance() {
        let iterations = 1000
        var receivedCount = 0
        let lock = UnfairQueue()

        // Set up multiple publishers
        for _ in 0..<10 {
            store.publisher(\.counter)
                .sink { _ in lock.sync { receivedCount += 1 } }
                .store(in: &cancellables)
        }
        
        measure(
            baseline: .init(1.1, stringTransformer: { String(format: "%.4fs", $0) })
        ) {
            receivedCount = 0
            
            for _ in 0..<iterations {
                store.dispatch(.increment)
            }
            
            // Wait for notifications
            let expectation = XCTestExpectation(description: "Notifications received")
            
            Task {
                await fulfillment(timeout: 10) {
                    self.store.state.counter == iterations
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
            
            // Reset
            store.dispatch(.reset)
        }
    }
    
    // MARK: - Complex State Tests
    
    /// Measures performance with complex state updates.
    func test_measureComplexStateUpdates() {
        let iterations = 1000
        let publisher = store
            .statePublisher
            .map { ($0.counter, $0.array.endIndex, $0.dictionary["key\(iterations - 1)"] != nil) }
            .filter { $0.0 == iterations && $0.1 == iterations && $0.2 }

        measure(
            baseline: .init(local: 1.6, ci: 2.5, stringTransformer: { String(format: "%.4fs", $0) })
        ) {
            for i in 0..<iterations {
                store.dispatch([
                    .increment,
                    .appendToArray(i),
                    .updateDictionary(key: "key\(i)", value: i)
                ])
            }

            // Wait for completion
            let sinkExpectation = XCTestExpectation(description: "Sink was called.")
            let cancellable = publisher
                .sink { _ in sinkExpectation.fulfill() }

            wait(for: [sinkExpectation], timeout: 5)

            // Reset
            store.dispatch(.reset)
            cancellable.cancel()
        }
    }
    
    // MARK: - Middleware Performance Tests
    
    /// Measures performance impact of middleware.
    func test_measureMiddlewareImpact() {
        // Add multiple middleware
        let middleware = (0..<10).map { _ in
            PerformanceMiddleware()
        }
        
        middleware.forEach { store.add($0) }
        
        let iterations = 1000
        
        measure(
            baseline: .init(1.1, stringTransformer: { String(format: "%.4fs", $0) })
        ) {
            for _ in 0..<iterations {
                store.dispatch(.increment)
            }
            
            // Wait for completion
            let expectation = XCTestExpectation(description: "With middleware")
            
            Task {
                await fulfillment(timeout: 10) {
                    self.store.state.counter == iterations
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
            
            // Reset
            store.dispatch(.reset)
        }
        
        // Clean up
        middleware.forEach { store.remove($0) }
    }
    
    // MARK: - Memory Performance Tests
    
    /// Tests memory usage with large state.
    func test_memoryUsageWithLargeState() {
        let iterations = 10000

        measure(
            baseline: .init(local: 13, ci: 24, stringTransformer: { String(format: "%.4fs", $0) }),
            iterations: 2
        ) {
            // Wait for completion
            let expectation = XCTestExpectation(description: "Large state")
            let cancellable = store
                .publisher(\.array)
                .map(\.endIndex)
                .filter { $0 == iterations }
                .sink { _ in expectation.fulfill() }

            let actions = (0..<iterations).map { PerformanceTestNamespace.Action.appendToArray($0) }
            actions.forEach { store.dispatch($0) }

            wait(for: [expectation])

            // Verify memory is released
            store.dispatch(.reset)
            cancellable.cancel()
        }
    }
}

// MARK: - Test Namespace

private enum PerformanceTestNamespace: StoreNamespace {
    typealias State = PerformanceTestState
    typealias Action = PerformanceTestAction
    
    static let identifier = "performance.test.store"
    
    static func reducers() -> [Reducer<Self>] {
        [PerformanceTestReducer()]
    }
}

// MARK: - Test State

private struct PerformanceTestState: Equatable {
    var counter: Int = 0
    var value: Int = 0
    var array: [Int] = []
    var dictionary: [String: Int] = [:]
    
    static let initial = PerformanceTestState()
}

// MARK: - Test Actions

private enum PerformanceTestAction: Sendable, StoreActionBoxProtocol {
    case increment
    case setValue(Int)
    case appendToArray(Int)
    case updateDictionary(key: String, value: Int)
    case reset
}

// MARK: - Test Reducer

private final class PerformanceTestReducer: Reducer<PerformanceTestNamespace>, @unchecked Sendable {
    override func reduce(
        state: PerformanceTestState,
        action: PerformanceTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> PerformanceTestState {
        var newState = state
        
        switch action {
        case .increment:
            newState.counter += 1
            
        case let .setValue(value):
            newState.value = value
            
        case let .appendToArray(value):
            newState.array.append(value)
            
        case let .updateDictionary(key, value):
            newState.dictionary[key] = value
            
        case .reset:
            newState = .initial
        }
        
        return newState
    }
}

// MARK: - Test Middleware

private final class PerformanceMiddleware: Middleware<PerformanceTestNamespace>, @unchecked Sendable {
    override func apply(
        state: PerformanceTestState,
        action: PerformanceTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        // Simulate some lightweight processing
        _ = state.counter * 2
    }
}
