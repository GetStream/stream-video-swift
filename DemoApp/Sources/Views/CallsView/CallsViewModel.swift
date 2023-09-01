//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import Combine

@MainActor
final class CallsViewModel: ObservableObject {

    @Injected(\.streamVideo) internal var streamVideo

    @Published internal var calls = [Call]()

    private var cancellables = Set<AnyCancellable>()

    private lazy var callsController: CallsController = {
        let sortParam = CallSortParam(direction: .descending, field: .createdAt)
        let filters: [String: RawJSON] = ["type": .dictionary(["$eq": .string("audio_room")])]
        let callsQuery = CallsQuery(sortParams: [sortParam], filters: filters, watch: true)
        return streamVideo.makeCallsController(callsQuery: callsQuery)
    }()

    init() {
        subscribeToCallsUpdates()
        loadCalls()
    }

    func onCallAppear(_ call: Call) {
        let index = calls.firstIndex { callData in
            callData.cId == call.cId
        }
        guard let index else { return }

        if index < calls.count - 10 {
            return
        }

        loadCalls()
    }

    func loadCalls() {
        Task {
            try await callsController.loadNextCalls()
        }
    }

    func subscribeToCallsUpdates() {
        callsController.$calls.sink { calls in
            DispatchQueue.main.async {
                self.calls = calls
            }
        }
        .store(in: &cancellables)
    }
}
