//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

extension Publisher {

    func asyncStreamSink(
        receiveCompletion: @escaping (Subscribers.Completion<Self.Failure>) -> Void = { _ in },
        _ handler: @escaping (Self.Output) -> Void
    ) -> AnyCancellable {
        if #available(iOS 15.0, *) {
            return Task {
                do {
                    for try await input in self.values {
                        handler(input)
                    }
                } catch let (error as Failure) {
                    receiveCompletion(.failure(error))
                } catch {
                    debugPrint("\(error)")
                }
            }
            .eraseToAnyCancellable()
        } else {
            return sink(
                receiveCompletion: receiveCompletion,
                receiveValue: handler
            )
        }
    }
}
