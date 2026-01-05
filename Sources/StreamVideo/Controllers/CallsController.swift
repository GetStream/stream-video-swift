//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// Controller used for querying and watching calls.
public class CallsController: ObservableObject, @unchecked Sendable {
    
    /// Observable list of calls.
    @Published public var calls = [Call]()
    
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
        
    private var next: String?
    private var prev: String?
        
    private let state = State()
    
    private let callsQuery: CallsQuery
    private let streamVideo: StreamVideo

    private var socketDisconnected = false
    private var disposableBag = DisposableBag()

    init(streamVideo: StreamVideo, callsQuery: CallsQuery) {
        self.callsQuery = callsQuery
        self.streamVideo = streamVideo
        subscribeToWatchEvents()
        subscribeToConnectionUpdates()
    }
    
    /// Loads the next page of calls.
    public func loadNextCalls() async throws {
        try await loadCalls()
    }
    
    public func cleanUp() {
        disposableBag.removeAll()
    }
    
    // MARK: - private
    
    private func subscribeToConnectionUpdates() {
        streamVideo.state.$connection.sink { [weak self] status in
            guard let self = self else { return }
            if case .disconnected = status {
                self.socketDisconnected = true
            } else if status == .disconnecting {
                self.socketDisconnected = true
            } else if status == .connected && self.socketDisconnected {
                self.reWatchCalls()
            }
        }
        .store(in: disposableBag)
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
            let response = try await streamVideo.queryCalls(request: request)
            if response.next == nil {
                await state.update(loadedAllCalls: true)
            }
            prev = response.prev
            next = response.next
            let calls = response.calls.map { call(from: $0) }
            if shouldRefresh {
                self.calls = calls
            } else {
                self.calls.append(contentsOf: calls)
            }
            await state.update(loading: false)
        } catch {
            log.error("Error querying calls", error: error)
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
        guard let callEvent = event.rawValue as? WSCallEvent else { return }
        for (index, call) in calls.enumerated() {
            if call.cId == callEvent.callCid {
                Task(disposableBag: disposableBag) { @MainActor [weak self] in
                    call.state.updateState(from: event)
                    self?.calls[index] = call
                }
                return
            }
        }
        if case let .typeCallCreatedEvent(callCreated) = event {
            let call = streamVideo.call(
                callType: callCreated.call.type,
                callId: callCreated.call.id
            )
            Task(disposableBag: disposableBag) { @MainActor [weak self] in
                call.state.update(from: callCreated)
                self?.calls.insert(call, at: 0)
            }
        }
    }

    private func call(from callResponse: CallStateResponseFields) -> Call {
        let call = streamVideo.call(
            callType: callResponse.call.type,
            callId: callResponse.call.id
        )
        Task(disposableBag: disposableBag) { @MainActor in
            call.state.update(from: callResponse)
        }
        return call
    }
    
    private func reWatchCalls() {
        socketDisconnected = false
        guard callsQuery.watch else { return }
        // Clean up and re-watch the calls
        prev = nil
        next = nil
        Task(disposableBag: disposableBag) { [weak self] in
            guard let self else { return }
            do {
                await state.update(loadedAllCalls: false)
                try await loadCalls(shouldRefresh: true)
            } catch {
                log.error(error)
            }
        }
    }
    
    private func subscribeToWatchEvents() {
        streamVideo
            .eventPublisher()
            .sink { [weak self] in self?.handle(event: $0) }
            .store(in: disposableBag)
    }
    
    deinit {
        cleanUp()
    }
}
