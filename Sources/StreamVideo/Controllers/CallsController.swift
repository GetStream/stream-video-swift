//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine

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
    private var cancellables = Set<AnyCancellable>()
        
    init(streamVideo: StreamVideo, defaultAPI: DefaultAPI, callsQuery: CallsQuery) {
        self.defaultAPI = defaultAPI
        self.callsQuery = callsQuery
        self.streamVideo = streamVideo
        self.subscribeToWatchEvents()
        self.subscribeToConnectionUpdates()
    }
    
    /// Loads the next page of calls.
    public func loadNextCalls() async throws {
        try await loadCalls()
    }
    
    public func cleanUp() {
        watchTask?.cancel()
        watchTask = nil
        for cancellable in cancellables {
            cancellable.cancel()
        }
        cancellables.removeAll()
    }
    
    // MARK: - private
    
    private func subscribeToConnectionUpdates() {
        streamVideo.$connectionStatus.sink { [weak self] status in
            guard let self = self else { return }
            if case .disconnected(_) = status {
                self.socketDisconnected = true
            } else if status == .disconnecting {
                self.socketDisconnected = true
            } else if status == .connected && socketDisconnected {
                reWatchCalls()
            }
        }
        .store(in: &cancellables)
    }
    
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
    
    private func handle(event: VideoEvent) {
        switch event {
        case .typeCallBroadcastingStartedEvent(let broadcastingStarted):
            let index = calls.firstIndex { callData in
                callData.call.cid == broadcastingStarted.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.egress.broadcasting = true
        case .typeCallBroadcastingStoppedEvent(let broadcastingStopped):
            let index = calls.firstIndex { callData in
                callData.call.cid == broadcastingStopped.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.egress.broadcasting = false
        case .typeCallCreatedEvent(let callCreated):
            let call = CallStateResponseFields(
                blockedUsers: [],
                call: callCreated.call,
                members: [],
                ownCapabilities: []
            )
            calls.insert(call, at: 0)
        case .typeCallEndedEvent(let callEnded):
            let index = calls.firstIndex { callData in
                callData.call.cid == callEnded.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.endedAt = Date()
        case .typeCallLiveStartedEvent(let liveStarted):
            let index = calls.firstIndex { callData in
                callData.call.cid == liveStarted.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call.backstage = false
        case .typeCallSessionParticipantJoinedEvent(let event):
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
        case .typeCallSessionParticipantLeftEvent(let event):
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
        case .typeCallUpdatedEvent(let callUpdated):
            let index = calls.firstIndex { callData in
                callData.call.cid == callUpdated.callCid
            }
            guard let index else {
                log.warning("Received an event for call that's not available")
                return
            }
            calls[index].call = callUpdated.call
        default:
            log.debug("Receivend an event \(event)")
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
