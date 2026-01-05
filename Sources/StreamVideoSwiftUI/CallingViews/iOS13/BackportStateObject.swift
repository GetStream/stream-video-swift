//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI

/// A property wrapper type that instantiates an observable object.
@propertyWrapper @available(iOS, introduced: 13, obsoleted: 14)
public final class BackportStateObject<ObjectType: ObservableObject & Sendable>: DynamicProperty, @unchecked Sendable
    where ObjectType.ObjectWillChangePublisher == ObservableObjectPublisher {
    
    /// Wrapper that helps with initialising without actually having an ObservableObject yet
    private class ObservedObjectWrapper: ObservableObject, @unchecked Sendable {
        @PublishedObject var wrappedObject: ObjectType? = nil
        init() {}
    }
    
    private var thunk: () -> ObjectType
    @ObservedObject private var observedObject = ObservedObjectWrapper()
    @State private var state = ObservedObjectWrapper()
    
    public var wrappedValue: ObjectType {
        if state.wrappedObject == nil {
            // There is no State yet so we need to initialise the object
            state.wrappedObject = thunk()
            // and start observing it
            observedObject.wrappedObject = state.wrappedObject
        } else if observedObject.wrappedObject == nil {
            // Retrieve the object from State and observe it in ObservedObject
            observedObject.wrappedObject = state.wrappedObject
        }
        return state.wrappedObject!
    }
    
    public var projectedValue: ObservedObject<ObjectType>.Wrapper {
        ObservedObject(wrappedValue: wrappedValue).projectedValue
    }
    
    public init(wrappedValue thunk: @autoclosure @escaping () -> ObjectType) {
        self.thunk = thunk
    }

    public nonisolated func update() {
        Task { @MainActor in
            // Not sure what this does but we'll just forward it
            _state.update()
            _observedObject.update()
        }
    }
}

/// Just like @Published this sends willSet events to the enclosing ObservableObject's ObjectWillChangePublisher
/// but unlike @Published it also sends the wrapped value's published changes on to the enclosing ObservableObject
@propertyWrapper @available(iOS, introduced: 13, obsoleted: 14)
public struct PublishedObject<Value> {

    public init(wrappedValue: Value) where Value: ObservableObject & Sendable,
        Value.ObjectWillChangePublisher == ObservableObjectPublisher {
        self.wrappedValue = wrappedValue
        cancellable = nil
        _startListening = { futureSelf, wrappedValue in
            let publisher = futureSelf._projectedValue
            let parent = futureSelf.parent
            futureSelf.cancellable = wrappedValue.objectWillChange.sink { [parent] in
                parent.objectWillChange?()
                DispatchQueue.main.async {
                    publisher.send(wrappedValue)
                }
            }
            publisher.send(wrappedValue)
        }
        startListening(to: wrappedValue)
    }
    
    public init<V>(wrappedValue: V?) where V? == Value, V: ObservableObject & Sendable,
        V.ObjectWillChangePublisher == ObservableObjectPublisher {
        self.wrappedValue = wrappedValue
        cancellable = nil
        _startListening = { futureSelf, wrappedValue in
            let publisher = futureSelf._projectedValue
            let parent = futureSelf.parent
            futureSelf.cancellable = wrappedValue?.objectWillChange.sink { [parent] in
                parent.objectWillChange?()
                DispatchQueue.main.async {
                    publisher.send(wrappedValue)
                }
            }
            publisher.send(wrappedValue)
        }
        startListening(to: wrappedValue)
    }

    public var wrappedValue: Value {
        willSet { parent.objectWillChange?() }
        didSet { startListening(to: wrappedValue) }
    }
    
    public static subscript<EnclosingSelf: ObservableObject & Sendable>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedObject>
    ) -> Value where EnclosingSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        get {
            observed[keyPath: storageKeyPath].setParent(observed)
            return observed[keyPath: storageKeyPath].wrappedValue
        }
        set {
            observed[keyPath: storageKeyPath].setParent(observed)
            observed[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
    
    public static subscript<EnclosingSelf: ObservableObject & Sendable>(
        _enclosingInstance observed: EnclosingSelf,
        projected wrappedKeyPath: KeyPath<EnclosingSelf, Publisher>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, PublishedObject>
    ) -> Publisher where EnclosingSelf.ObjectWillChangePublisher == ObservableObjectPublisher {
        observed[keyPath: storageKeyPath].setParent(observed)
        return observed[keyPath: storageKeyPath].projectedValue
    }

    private let parent = Holder()
    private var cancellable: AnyCancellable?
    private class Holder {
        var objectWillChange: (() -> Void)?
        init() {}
    }
    
    private func setParent<Parent: ObservableObject & Sendable>(_ parentObject: Parent)
        where Parent.ObjectWillChangePublisher == ObservableObjectPublisher {
        guard parent.objectWillChange == nil else { return }
        parent.objectWillChange = { [weak parentObject] in
            Task { @MainActor [weak parentObject] in
                try? await Task.sleep(nanoseconds: 10_000_000)
                parentObject?.objectWillChange.send()
            }
        }
    }
    
    private var _startListening: (inout Self, _ toValue: Value) -> Void
    private mutating func startListening(to wrappedValue: Value) {
        _startListening(&self, wrappedValue)
    }
    
    public typealias Publisher = AnyPublisher<Value, Never>
    
    private lazy var _projectedValue = CurrentValueSubject<Value, Never>(wrappedValue)
    public var projectedValue: Publisher {
        mutating get { _projectedValue.eraseToAnyPublisher() }
    }
}
