//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension Publisher {
    public func sinkTask(
        storeIn disposableBag: DisposableBag? = nil,
        identifier: String = UUID().uuidString,
        receiveCompletion: @escaping ((Subscribers.Completion<Failure>) -> Void) = { _ in },
        receiveValue: @escaping ((Output) async throws -> Void)
    ) -> AnyCancellable {
        sink(receiveCompletion: receiveCompletion) { [weak disposableBag] input in
            let task = Task {
                do {
                    try Task.checkCancellation()
                    try await receiveValue(input)
                } catch let error as Failure {
                    receiveCompletion(.failure(error))
                } catch is CancellationError {
                    if let error = ClientError("Task was cancelled.") as? Failure {
                        receiveCompletion(.failure(error))
                    }
                } catch {
                    LogConfig.logger.error(error)
                }
            }

            if let disposableBag {
                task.store(in: disposableBag, key: identifier)
            }
        }
    }
}
