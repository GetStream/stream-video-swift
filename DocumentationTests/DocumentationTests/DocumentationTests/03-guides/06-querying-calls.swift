//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

@MainActor
private func content() {
    asyncContainer {
        let filters: [String: RawJSON] = ["ended_at": .nil]
        let sort = [SortParamRequest.descending("created_at")]
        let limit = 10

        // Fetch the first page of calls
        let (firstPageCalls, secondPageCursor) = try await streamVideo.queryCalls(
            filters: filters,
            sort: sort,
            limit: limit
        )

        // Use the cursor we received from the previous call to fetch the second page
        let (secondPageCalls, _) = try await streamVideo.queryCalls(next: secondPageCursor)
    }

    container {
        var callsController: CallsController = {
            let sortParam = CallSortParam(direction: .descending, field: .createdAt)
            let filters: [String: RawJSON] = ["type": .dictionary(["$eq": .string("audio_room")])]
            let callsQuery = CallsQuery(sortParams: [sortParam], filters: filters, watch: true)
            return streamVideo.makeCallsController(callsQuery: callsQuery)
        }()
    }

    container {
        let filters: [String: RawJSON] = ["type": .dictionary(["$eq": .string("audio_room")])]
    }

    container {
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

        viewContainer {
            let callsViewModel = CallsViewModel()

            ScrollView {
                LazyVStack {
                    ForEach(callsViewModel.calls, id: \.callId) { _ in
                        CallView(viewFactory: viewFactory, viewModel: viewModel)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}
