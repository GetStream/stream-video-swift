//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

/// Tests for specific race conditions and edge cases in Store.
///
/// These tests target specific threading scenarios that could cause issues:
/// - Read/write races
/// - Middleware state access during updates
/// - Publisher timing issues
/// - Cleanup during active operations
final class Store_RaceConditionTests: XCTestCase, @unchecked Sendable {
    
    private var store: Store<RaceTestNamespace>!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        store = RaceTestNamespace.store(initialState: .initial)
    }
    
    override func tearDown() {
        cancellables = nil
        store = nil
        super.tearDown()
    }
    
    // MARK: - State Read/Write Race Tests
    
    /// Tests reading state while it's being updated.
    func test_stateReadDuringWrite_isConsistent() async throws {
        // Given
        let iterations = 1000
        nonisolated(unsafe) var capturedStates: [RaceTestState] = []
        let lock = UnfairQueue()

        // Start reading state continuously
        let readTask = Task {
            for _ in 0..<iterations * 10 {
                let state = store.state
                lock.sync { capturedStates.append(state) }

                // Small delay to interleave with writes
                try? await Task.sleep(nanoseconds: 100)
            }
        }

        // Concurrently write to state
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { [weak self] in
                    self?.store.dispatch(.update(id: i, value: i))
                }
            }

            await group.waitForAll()
        }

        _ = await readTask.result
        // Cancel read task
        readTask.cancel()
        
        // Then: All captured states should be valid
        for state in capturedStates {
            // Check internal consistency
            for (key, value) in state.data {
                XCTAssertEqual(
                    key,
                    value,
                    "State should maintain internal consistency"
                )
            }
        }
    }
    
    /// Tests middleware accessing state during concurrent updates.
    func test_middlewareStateAccess_duringConcurrentUpdates() async throws {
        // Given
        let middleware = StateCapturingMiddleware()
        store.add(middleware)
        
        let iterations = 100
        
        // When: Dispatch many actions concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask { [weak self] in
                    self?.store.dispatch(.update(id: i, value: i))
                }
            }
        }
        
        // Wait for processing
        await fulfillment(timeout: 5) {
            self.store.state.data.count >= iterations
        }
        
        // Then: Verify middleware captured valid states
        let capturedStates = middleware.capturedStates
        XCTAssertGreaterThan(capturedStates.count, 0)
        
        for state in capturedStates {
            // Verify state consistency
            for (key, value) in state.data {
                XCTAssertEqual(key, value, "Captured state should be consistent")
            }
        }
    }
    
    // MARK: - Publisher Race Tests
    
    /// Tests publisher behavior when state changes rapidly.
    func test_publisher_withRapidStateChanges() async throws {
        // Given
        let iterations = 1000
        nonisolated(unsafe) var receivedValues: [Int] = []
        let lock = UnfairQueue()
        var isCompleted = false
        
        // Subscribe to counter
        store.publisher(\.counter)
            .handleEvents(receiveCompletion: { _ in
                lock.sync { isCompleted = true }
            })
            .sink { value in
                lock.sync { receivedValues.append(value) }
            }
            .store(in: &cancellables)
        
        // When: Rapidly change state
        for i in 0..<iterations {
            store.dispatch(.setCounter(i))
        }
        
        // Wait for final value
        await fulfillment(timeout: 5) {
            lock.sync { receivedValues.last == iterations - 1 }
        }
        
        // Then: Verify publisher behavior
        XCTAssertFalse(isCompleted, "Publisher should not complete")
        XCTAssertGreaterThan(receivedValues.count, 0)
        
        // Values should be in ascending order (though some may be skipped)
        for i in 1..<receivedValues.count {
            XCTAssertGreaterThanOrEqual(
                receivedValues[i],
                receivedValues[i - 1],
                "Values should be monotonically increasing"
            )
        }
    }
    
    /// Tests creating publishers during state updates.
    func test_creatingPublisher_duringStateUpdate() async throws {
        // Given
        let iterations = 100
        nonisolated(unsafe) var publishers: [AnyCancellable] = []
        let lock = UnfairQueue()

        // When: Create publishers while updating state
        await withTaskGroup(of: Void.self) { group in
            // Update state
            for i in 0..<iterations {
                group.addTask { [weak self] in
                    self?.store.dispatch(.setCounter(i))
                }
            }
            
            // Create publishers
            for _ in 0..<iterations {
                group.addTask { [weak self] in
                    guard let self else { return }
                    
                    let cancellable = self.store.publisher(\.counter)
                        .sink { _ in }
                    
                    lock.sync { publishers.append(cancellable) }
                }
            }
        }
        
        // Then: All publishers should be valid
        XCTAssertEqual(publishers.count, iterations)
        
        // Store should still be functional
        let finalValue = 999
        store.dispatch(.setCounter(finalValue))
        
        await fulfillment(timeout: 2) {
            self.store.state.counter == finalValue
        }
    }

    // MARK: - Cleanup Race Tests
    
    /// Tests store cleanup while operations are active.
    func test_storeCleanup_withActiveOperations() async throws {
        // Given
        nonisolated(unsafe) var localStore: Store<RaceTestNamespace>? = RaceTestNamespace.store(
            initialState: .initial
        )
        
        let iterations = 100
        
        // When: Start operations and deallocate store
        let task = Task {
            guard let store = localStore else { return }
            
            for i in 0..<iterations {
                store.dispatch(.setCounter(i))
                
                // Deallocate store mid-operation
                if i == iterations / 2 {
                    localStore = nil
                }
            }
        }
        
        // Wait for task completion
        _ = await task.result
        
        // Then: No crash should occur
        XCTAssertNil(localStore, "Store should be deallocated")
    }
    
    /// Tests publisher cleanup during active notifications.
    func test_publisherCleanup_duringNotifications() async throws {
        // Given
        let iterations = 100
        var receivedCount = 0
        let lock = NSLock()
        
        // Create publisher that will be cancelled during notifications
        var localCancellables = Set<AnyCancellable>()
        
        store.publisher(\.counter)
            .sink { _ in
                lock.lock()
                receivedCount += 1
                lock.unlock()
                
                // Cancel subscription during notification
                if receivedCount == 50 {
                    localCancellables.removeAll()
                }
            }
            .store(in: &localCancellables)
        
        // When: Dispatch many actions
        for i in 0..<iterations {
            store.dispatch(.setCounter(i))
        }
        
        // Wait a bit
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Then: Verify partial reception
        XCTAssertGreaterThanOrEqual(receivedCount, 50)
        XCTAssertLessThan(
            receivedCount,
            iterations,
            "Should stop receiving after cancellation"
        )
    }
}

// MARK: - Test Namespace

private enum RaceTestNamespace: StoreNamespace {
    typealias State = RaceTestState
    typealias Action = RaceTestAction
    
    static let identifier = "race.test.store"
    
    static func reducers() -> [Reducer<Self>] {
        [RaceTestReducer()]
    }
}

// MARK: - Test State

private struct RaceTestState: Equatable {
    var counter: Int = 0
    var data: [Int: Int] = [:]
    var slowOperationComplete: Bool = false
    
    static let initial = RaceTestState()
}

// MARK: - Test Actions

private enum RaceTestAction: Sendable, StoreActionBoxProtocol {
    case setCounter(Int)
    case update(id: Int, value: Int)
    case slowOperation
}

// MARK: - Test Reducer

private final class RaceTestReducer: Reducer<RaceTestNamespace>, @unchecked Sendable {
    override func reduce(
        state: RaceTestState,
        action: RaceTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> RaceTestState {
        var newState = state
        
        switch action {
        case let .setCounter(value):
            newState.counter = value
            
        case let .update(id, value):
            newState.data[id] = value
            
        case .slowOperation:
            // Simulate slow operation
            Thread.sleep(forTimeInterval: 0.01)
            newState.slowOperationComplete = true
        }
        
        return newState
    }
}

// MARK: - Test Middleware

private final class StateCapturingMiddleware: Middleware<RaceTestNamespace>, @unchecked Sendable {
    @Atomic private(set) var capturedStates: [RaceTestState] = []
    
    override func apply(
        state: RaceTestState,
        action: RaceTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        // Capture state
        capturedStates.append(state)

        // Access state through provider
        if let currentState = self.state {
            // Verify we can read state
            _ = currentState.counter
        }
    }
}

private final class SlowMiddleware: Middleware<RaceTestNamespace>, @unchecked Sendable {
    @Atomic private(set) var processedCount = 0
    
    override func apply(
        state: RaceTestState,
        action: RaceTestAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) {
        // Simulate slow processing
        Thread.sleep(forTimeInterval: 0.01)
        
        processedCount += 1
    }
}
