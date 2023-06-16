//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// Controller used for querying and watching calls.
public class CallsController: ObservableObject {
    
    /// Observable list of calls.
    @Published public var calls = [CallStateResponseFields]()
    
    actor State {
        var loading = false
        var loadedAllCalls = false
        
        func update(loading: Bool) {
            self.loading = loading
        }
        
        func update(loadedAllCalls: Bool) {
            self.loadedAllCalls = loadedAllCalls
        }
    }
    
    private let defaultAPI: DefaultAPI
    
    private var next: String?
    private var prev: String?
        
    private let state = State()
    
    private let callsQuery: CallsQuery
    private let streamVideo: StreamVideo
    
    private var watchTask: Task<Void, Error>?
    private var socketDisconnected = false
        
    init(streamVideo: StreamVideo, defaultAPI: DefaultAPI, callsQuery: CallsQuery) {
        self.defaultAPI = defaultAPI
        self.callsQuery = callsQuery
        self.streamVideo = streamVideo
        self.subscribeToWatchEvents()
    }
    
    /// Loads the next page of calls.
    public func loadNextCalls() async throws {
        try await loadCalls()
    }
    
    public func cleanUp() {
        watchTask?.cancel()
        watchTask = nil
    }
    
    // MARK: - private
    
    private func loadCalls(shouldRefresh: Bool = false) async throws {
        let isLoading = await state.loading
        let loadedAllCalls = await state.loadedAllCalls
        if isLoading || loadedAllCalls {
            return
        }
        await state.update(loading: true)
                
        let request = makeQueryCallsRequest()
        
        do {
            let response = try await defaultAPI.queryCalls(queryCallsRequest: request)
            if response.next == nil {
                await state.update(loadedAllCalls: true)
            }
            prev = response.prev
            next = response.next
            let calls = response.calls
            if shouldRefresh {
                self.calls = calls
            } else {
                self.calls.append(contentsOf: calls)
            }
            await state.update(loading: false)
        } catch {
            log.error("Error querying calls \(error.localizedDescription)")
            await state.update(loading: false)
            throw error
        }
    }
    
    private func makeQueryCallsRequest() -> QueryCallsRequest {
        let sortParams = makeSortParamsRequest()
        let filterConditions = makeFilterConditions()
        
        let request = QueryCallsRequest(
            filterConditions: filterConditions,
            limit: callsQuery.pageSize,
            next: next,
            prev: prev,
            sort: sortParams,
            watch: callsQuery.watch
        )
        return request
    }
    
    private func makeSortParamsRequest() -> [SortParamRequest] {
        var sortParams = [SortParamRequest]()
        for sortParam in callsQuery.sortParams {
            let param = SortParamRequest(
                direction: sortParam.direction.rawValue,
                field: sortParam.field.rawValue
            )
            sortParams.append(param)
        }
        return sortParams
    }
    
    private func makeFilterConditions() -> [String: RawJSON]? {
        var filterConditions: [String: RawJSON]?
        if let filters = callsQuery.filters {
            filterConditions = [String: RawJSON]()
            for (key, filter) in filters {
                filterConditions?[key] = filter
            }
        }
        return filterConditions
    }
    
    private func handle(event: Event) {
        if let callUpdated = event as? CallUpdatedEvent {
            let index = calls.firstIndex { callData in
                callData.call.cid == callUpdated.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call = callUpdated.call
        } else if let callCreated = event as? CallCreatedEvent {
            let call = CallStateResponseFields(
                blockedUsers: [],
                call: callCreated.call,
                members: [],
                ownCapabilities: []
            )
            calls.insert(call, at: 0)
        } else if let broadcastingStarted = event as? CallBroadcastingStartedEvent {
            let index = calls.firstIndex { callData in
                callData.call.cid == broadcastingStarted.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.egress.broadcasting = true
        } else if let broadcastingStopped = event as? CallBroadcastingStoppedEvent {
            let index = calls.firstIndex { callData in
                callData.call.cid == broadcastingStopped.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.egress.broadcasting = false
        } else if let liveStarted = event as? CallLiveStartedEvent {
            let index = calls.firstIndex { callData in
                callData.call.cid == liveStarted.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.backstage = false
        } else if let callEnded = event as? CallEndedEvent {
            let index = calls.firstIndex { callData in
                callData.call.cid == callEnded.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.endedAt = Date()
        } else if let event = event as? CallSessionParticipantJoinedEvent {
            let index = calls.firstIndex { callData in
                callData.call.cid == event.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            let participant = CallParticipantResponse(
                joinedAt: event.createdAt,
                user: event.user
            )
            calls[index].call.session?.participants.append(participant)
        } else if let event = event as? CallSessionParticipantLeftEvent {
            let index = calls.firstIndex { callData in
                callData.call.cid == event.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.session?.participants.removeAll(where: { participant in
                participant.user.id == event.user.id
            })
        } else if event is WSDisconnected {
            self.socketDisconnected = true
        } else if event is WSConnected {
            if socketDisconnected {
                reWatchCalls()
            }
        }
    }
    
    private func reWatchCalls() {
        socketDisconnected = false
        guard callsQuery.watch else { return }
        // Clean up and re-watch the calls
        prev = nil
        next = nil
        Task {
            await state.update(loadedAllCalls: false)
            try await loadCalls(shouldRefresh: true)
        }
    }
    
    private func subscribeToWatchEvents() {
        watchTask = Task {
            for await event in streamVideo.subscribe() {
                handle(event: event)
            }
        }
    }
    
    deinit {
        cleanUp()
    }
}
