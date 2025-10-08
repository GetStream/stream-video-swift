//
//  SafePublished.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 8/10/25.
//

import Foundation
import Combine

@propertyWrapper
public struct SafePublished<T> {
    private let subject: CurrentValueSubject<T, Never>
    private let removeDuplicates: Bool

    public var wrappedValue: T { subject.value }
    public let publisher: AnyPublisher<T, Never>

    public init(wrappedValue: T) {
        self.subject = .init(wrappedValue)
        self.removeDuplicates = false
        self.publisher = subject
            .eraseToAnyPublisher()
    }

    public init(wrappedValue: T, removeDuplicates: Bool = true) where T: Equatable {
        self.subject = .init(wrappedValue)
        self.removeDuplicates = removeDuplicates
        if removeDuplicates {
            self.publisher = subject
                .removeDuplicates()
                .eraseToAnyPublisher()
        } else {
            self.publisher = subject
                .eraseToAnyPublisher()
        }
    }

    public func set(_ newValue: T) {
        subject.send(newValue)
    }
}
