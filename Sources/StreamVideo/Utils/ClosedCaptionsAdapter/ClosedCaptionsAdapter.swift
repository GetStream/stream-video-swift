//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/**
 A class responsible for managing closed captions in a call.

 This class handles the subscription to closed caption events and updates the
 call state with the received captions. It uses an `OrderedCapacityQueue` to
 manage the captions with a specified capacity and presentation duration.

 - Parameters:
    - capacity: The maximum number of captions to store.
    - itemPresentationDuration: The duration for which each caption is presented.
 */
final class ClosedCaptionsAdapter {

    var capacity: Int {
        didSet { items.capacity = capacity }
    }

    var itemPresentationDuration: TimeInterval {
        didSet { items.removalTime = itemPresentationDuration }
    }

    private var cancellable: AnyCancellable?
    private var itemsCancellable: AnyCancellable?
    private let items: OrderedCapacityQueue<CallClosedCaption>
    private let disposableBag = DisposableBag()

    /**
     Initializes a new instance of `ClosedCaptionsAdapter`.

     - Parameters:
        - call: The call instance to subscribe for closed caption events.
        - capacity: The maximum number of captions to store. Default is 2.
        - itemPresentationDuration: The duration for which each caption is
          presented. Default is 2.7 seconds.
     */
    init(
        _ call: Call,
        capacity: Int = 2,
        itemPresentationDuration: TimeInterval = 2.7
    ) {
        items = .init(capacity: capacity, removalTime: itemPresentationDuration)
        self.capacity = capacity
        self.itemPresentationDuration = itemPresentationDuration

        configure(with: call)
    }

    /// Cancels any ongoing subscriptions when the instance is deallocated.
    deinit {
        cancellable?.cancel()
        itemsCancellable?.cancel()
    }

    /// Stops the closed captions adapter by cancelling all subscriptions.
    func stop() {
        cancellable?.cancel()
        itemsCancellable?.cancel()
    }

    // MARK: - Private Helpers

    /**
     Configures the adapter with the given call instance.

     This method sets up the subscriptions to closed caption events and updates
     the call state with the received captions.

     - Parameter call: The call instance to subscribe for closed caption events.
     */
    private func configure(with call: Call) {
        cancellable = call
            .eventPublisher(for: ClosedCaptionEvent.self)
            .map(\.closedCaption)
            .removeDuplicates()
            .log(.debug) { "Processing closedCaption for speakerId:\($0.speakerId) text:\($0.text)." }
            .sink { [weak self] in self?.items.append($0) }

        itemsCancellable = items
            .publisher
            .sinkTask(storeIn: disposableBag) { @MainActor [weak call] in call?.state.update(closedCaptions: $0) }
    }
}
