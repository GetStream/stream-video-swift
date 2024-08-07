//
//  Publisher+TaskSing.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 8/8/24.
//

import Foundation
import Combine

public struct TaskSink<Input, Failure: Error>: Subscriber {
    public var combineIdentifier: CombineIdentifier { .init() }
    
    public typealias Completion = (Result<Void, Failure>) -> Void

    private let task: @Sendable (Input) async throws -> Void
    private let disposableBag: DisposableBag?
    private let identifier: String
    private let completion: Completion?

    public init(
        task: @escaping @Sendable (Input) async throws -> Void,
        storeIn disposableBag: DisposableBag?,
        with identifier: String,
        completion: Completion? = nil
    ) {
        self.task = task
        self.disposableBag = disposableBag
        self.identifier = identifier
        self.completion = completion
    }

    public func receive(subscription: Subscription) {
        subscription.request(.unlimited)
    }

    public func receive(_ input: Input) -> Subscribers.Demand {
        if let disposableBag {
            Task {
                do {
                    try await task(input)
                } catch {
                    completion?(.failure(error as! Failure))
                }
            }
            .store(in: disposableBag, key: identifier)
        } else {
            Task {
                do {
                    try await task(input)
                } catch {
                    completion?(.failure(error as! Failure))
                }
            }
        }
        return .none
    }

    public func receive(completion: Subscribers.Completion<Failure>) {
        switch completion {
        case .finished:
            self.completion?(.success(()))
        case .failure(let error):
            self.completion?(.failure(error))
        }
    }
}

extension Publisher {
    public func sinkTask(
        receiveCompletion: ((Subscribers.Completion<Failure>) -> Void)? = nil,
        storeIn disposableBag: DisposableBag? = nil,
        with identifier: String = UUID().uuidString,
        task: @escaping @Sendable (Output) async throws -> Void
    ) -> AnyCancellable {
        let sink = TaskSink<Output, Failure>(
            task: task,
            storeIn: disposableBag,
            with: identifier
        ) { result in
            switch result {
            case .success:
                receiveCompletion?(.finished)
            case .failure(let error):
                receiveCompletion?(.failure(error))
            }
        }
        self.subscribe(sink)
        return AnyCancellable { sink.receive(completion: .finished) }
    }
}
