//
//  CallsViewModel.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 13.4.23.
//

import Foundation
import StreamVideo
import Combine

@MainActor
class CallsViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published var calls = [CallData]()
    
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
    
    func onCallAppear(_ call: CallData) {
        let index = calls.firstIndex { callData in
            callData.callCid == call.callCid
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
    
    private func subscribeToCallsUpdates() {
        callsController.$calls.sink { calls in
            DispatchQueue.main.async {
                self.calls = calls
            }
        }
        .store(in: &cancellables)
    }
    
}

extension CallData: Identifiable {
    public var id: String {
        callCid
    }
}
