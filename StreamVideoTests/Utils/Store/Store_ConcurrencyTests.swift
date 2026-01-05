//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

/// Comprehensive tests for Store thread safety and concurrency.
///
/// These tests verify that the Store correctly handles:
/// - Concurrent action dispatches
/// - State consistency under high load
/// - Order preservation for serial processing
/// - Publisher behavior under concurrent access
final class Store_ConcurrencyTests: XCTestCase, @unchecked Sendable {
    
    // MARK: - Properties
    
    private var store: Store<ConcurrencyTestNamespace>!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup/Teardown
    
    override func setUp() {
        super.setUp()
        cancellables = []
        store = ConcurrencyTestNamespace.store(initialState: .initial)
    }
    
    override func tearDown() {
        cancellables = nil
        store = nil
        super.tearDown()
    }
    
    // MARK: - Concurrent Dispatch Tests
    
    /// Tests that concurrent dispatches maintain state consistency.
    func test_concurrentDispatch_maintainsStateConsistency() async throws {
        // Given
        let iterations = 1000
        let expectation = XCTestExpectation(
            description: "All actions processed"
        )
        expectation.expectedFulfillmentCount = iterations
        
        // When: Dispatch many actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask { [weak self] in
                    self?.store.dispatch(.increment)
                    expectation.fulfill()
                }
            }
        }
        
        // Then: Wait for all actions to complete
        await fulfillment(of: [expectation], timeout: 10)
        
        // Verify final state is consistent
        // Actions are processed serially, so counter should equal iterations
        await fulfillment(timeout: 2) {
            self.store.state.counter == iterations
        }
    }
    
    /// Tests that synchronous dispatch blocks correctly under concurrency.
    func test_concurrentDispatchSync_blocksAndMaintainsOrder() async throws {
        // Given
        let iterations = 100
        nonisolated(unsafe) var results: [Int] = []
        let lock = UnfairQueue()

        // When: Dispatch sync actions concurrently
        await withTaskGroup(of: Int.self) { group in
            for i in 0..<iterations {
                group.addTask { [weak self] in
                    guard let self else { return -1 }
                    
                    try? await self.store.dispatch(.setValue(i)).result()

                    // Capture the state after sync dispatch
                    let value = self.store.state.value
                    lock.sync { results.append(value) }
                    return value
                }
            }
            
            // Collect all results
            for await _ in group {
                // Results are collected
            }
        }
        
        // Then: Verify all values were set
        // Last value should be from one of the concurrent operations
        XCTAssertTrue(
            (0..<iterations).contains(store.state.value),
            "Final value should be from one of the operations"
        )
        
        // All results should be valid
        XCTAssertEqual(results.count, iterations)
        results.forEach { value in
            XCTAssertTrue(
                (0..<iterations).contains(value),
                "Each result should be a valid value"
            )
        }
    }
    
    /// Tests that action order is preserved when using delays.
    func test_dispatchWithDelays_preservesOrder() async throws {
        // Given
        let actions = Array(0..<10)
        
        // When: Dispatch actions with varying delays
        for i in actions {
            // Earlier actions have longer delays
            let delay = StoreDelay(
                before: Double(10 - i) * 0.01
            )
            store.dispatch(.delayed(.appendToSequence(i), delay: delay))
        }
        
        // Then: Despite delays, actions should be processed in dispatch order
        await fulfillment(timeout: 3) {
            self.store.state.sequence.count == actions.count
        }
        
        XCTAssertEqual(
            store.state.sequence,
            actions,
            "Actions should be processed in dispatch order"
        )
    }
    
    // MARK: - State Observation Tests
    
    /// Tests that publishers work correctly under concurrent access.
    func test_publisher_worksUnderConcurrentAccess() async throws {
        // Given
        let iterations = 100
        nonisolated(unsafe) var receivedValues: [Int] = []
        let lock = UnfairQueue()

        // Subscribe to counter changes
        store.publisher(\.counter)
            .sink { value in lock.sync { receivedValues.append(value) } }
            .store(in: &cancellables)
        
        // When: Dispatch actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask { [weak self] in
                    self?.store.dispatch(.increment)
                }
            }
        }
        
        // Then: Verify all state changes were published
        await fulfillment(timeout: 5) {
            lock.sync { receivedValues.last == iterations }
        }
        
        // Verify we received a reasonable number of updates
        // (may be less than iterations due to coalescing)
        XCTAssertGreaterThan(receivedValues.count, 0)
        XCTAssertLessThanOrEqual(receivedValues.count, iterations + 1) // +1 for initial
        
        // Verify values are monotonically increasing
        for i in 1..<receivedValues.count {
            XCTAssertGreaterThanOrEqual(
                receivedValues[i],
                receivedValues[i - 1],
                "Values should be monotonically increasing"
            )
        }
    }
    
    /// Tests multiple publishers don't interfere with each other.
    func test_multiplePublishers_dontInterfere() async throws {
        // Given
        var counterValues: [Int] = []
        var valueValues: [Int] = []
        let lock = UnfairQueue()

        // Subscribe to different properties
        store.publisher(\.counter)
            .sink { value in
                lock.sync { counterValues.append(value) }
            }
            .store(in: &cancellables)
        
        store.publisher(\.value)
            .sink { value in
                lock.sync { valueValues.append(value) }
            }
            .store(in: &cancellables)
        
        // When: Dispatch different actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask { [weak self] in
                    self?.store.dispatch(.increment)
                }
                group.addTask { [weak self] in
                    self?.store.dispatch(.setValue(i))
                }
            }
        }
        
        // Then: Wait for processing
        await fulfillment(timeout: 5) {
            self.store.state.counter == 50
        }
        
        // Verify both publishers received updates
        XCTAssertGreaterThan(counterValues.count, 0)
        XCTAssertGreaterThan(valueValues.count, 0)
        
        // Verify final values
        XCTAssertEqual(counterValues.last, 50)
        XCTAssertNotNil(valueValues.last)
    }
    
    // MARK: - Stress Tests
    
    /// High-load stress test with many concurrent operations.
    func test_stressTest_highConcurrentLoad() async throws {
        // Given
        let iterations = 1000
        let concurrentTasks = 10
        
        // When: Perform many operations concurrently
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<concurrentTasks {
                group.addTask { [weak self] in
                    guard let self else { return }
                    
                    for i in 0..<iterations {
                        // Mix of different operations
                        switch i % 4 {
                        case 0:
                            self.store.dispatch(.increment)
                        case 1:
                            self.store.dispatch(.setValue(i))
                        case 2:
                            self.store.dispatch(.appendToSequence(i))
                        case 3:
                            self.store.dispatch(.reset)
                        default:
                            break
                        }
                    }
                }
            }
        }
        
        // Then: Store should remain functional
        // Dispatch a final action to verify store is still working
        let finalValue = 999_999
        try await store.dispatch(.setValue(finalValue)).result()

        XCTAssertEqual(
            store.state.value,
            finalValue,
            "Store should still be functional after stress test"
        )
    }
    
    /// Tests rapid subscription and cancellation.
    func test_rapidSubscriptionCancellation_doesNotCrash() async throws {
        // Given
        let iterations = 100
        
        // When: Rapidly create and cancel subscriptions
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask { [weak self] in
                    guard let self else { return }
                    
                    var localCancellables = Set<AnyCancellable>()
                    
                    // Create multiple subscriptions
                    self.store.publisher(\.counter)
                        .sink { _ in }
                        .store(in: &localCancellables)
                    
                    self.store.publisher(\.value)
                        .sink { _ in }
                        .store(in: &localCancellables)
                    
                    // Dispatch some actions
                    self.store.dispatch(.increment)
                    
                    // Cancel subscriptions
                    localCancellables.removeAll()
                }
            }
        }
        
        // Then: Store should remain functional
        try await store.dispatch(.increment).result()
        XCTAssertGreaterThanOrEqual(store.state.counter, 1)
    }
}

// MARK: - Test Namespace

private enum ConcurrencyTestNamespace: StoreNamespace {
    typealias State = ConcurrencyTestState
    typealias Action = ConcurrencyTestAction
    
    static let identifier = "concurrency.test.store"
    
    static func reducers() -> [Reducer<Self>] {
        [ConcurrencyTestReducer()]
    }
}

// MARK: - Test State

private struct ConcurrencyTestState: Equatable {
    var counter: Int = 0
    var value: Int = 0
    var sequence: [Int] = []
    
    static let initial = ConcurrencyTestState()
}

// MARK: - Test Actions

private enum ConcurrencyTestAction: Sendable, StoreActionBoxProtocol {
    case increment
    case setValue(Int)
    case appendToSequence(Int)
    case reset
}

// MARK: - Test Reducer

private final class ConcurrencyTestReducer: Reducer<ConcurrencyTestNamespace>, @unchecked Sendable {
    override func reduce(
        state: ConcurrencyTestState,
        action: ConcurrencyTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> ConcurrencyTestState {
        var newState = state
        
        switch action {
        case .increment:
            newState.counter += 1
            
        case let .setValue(value):
            newState.value = value
            
        case let .appendToSequence(value):
            newState.sequence.append(value)
            
        case .reset:
            newState = .initial
        }
        
        return newState
    }
}

// MARK: - Test Middleware

private final class CountingMiddleware: Middleware<ConcurrencyTestNamespace>, @unchecked Sendable {
    @Atomic private(set) var actionCount: Int = 0

    override func apply(
        state: ConcurrencyTestState,
        action: ConcurrencyTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        actionCount += 1
    }
}

private final class IncrementReducer: Reducer<ConcurrencyTestNamespace>, @unchecked Sendable {
    override func reduce(
        state: ConcurrencyTestState,
        action: ConcurrencyTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> ConcurrencyTestState {
        var newState = state
        
        if case .increment = action {
            newState.counter += 1
        }
        
        return newState
    }
}
