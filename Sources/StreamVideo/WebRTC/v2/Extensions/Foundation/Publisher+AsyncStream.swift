//
//  Publisher+AsyncStream.swift
//  StreamVideo
//
//  Created by Ilias Pavlidakis on 9/8/24.
//

import Foundation
import Combine

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
                } catch (let error as Failure) {
                    receiveCompletion(.failure(error))
                } catch {
                    debugPrint("\(error)")
                }
            }
            .eraseToAnyCancellable()
        } else {
            return self
                .sink(
                    receiveCompletion: receiveCompletion,
                    receiveValue: handler
                )
        }
    }
}

