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
        
        measure {
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
        measure {
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
        
        measure {
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
        
        measure {
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
        
        measure {
            for i in 0..<iterations {
                // Mix of different state updates
                store.dispatch(.increment)
                store.dispatch(.appendToArray(i))
                store.dispatch(.updateDictionary(key: "key\(i)", value: i))
            }
            
            // Wait for completion
            let expectation = XCTestExpectation(description: "Complex updates")
            
            Task {
                await fulfillment(timeout: 10) {
                    self.store.state.counter == iterations
                        && self.store.state.array.count == iterations
                        && self.store.state.dictionary.count == iterations
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10)
            
            // Reset
            store.dispatch(.reset)
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
        
        measure {
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
        
        measure {
            autoreleasepool {
                for i in 0..<iterations {
                    store.dispatch(.appendToArray(i))
                }
                
                // Wait for completion
                let expectation = XCTestExpectation(description: "Large state")
                
                Task {
                    await fulfillment(timeout: 10) {
                        self.store.state.array.count == iterations
                    }
                    expectation.fulfill()
                }
                
                wait(for: [expectation], timeout: 10)
                
                // Verify memory is released
                store.dispatch(.reset)
            }
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
    ) throws -> PerformanceTestState {
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
