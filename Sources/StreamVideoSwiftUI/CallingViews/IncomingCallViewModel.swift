//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamVideo

@MainActor
public class IncomingViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    public private(set) var callInfo: IncomingCall
    
    @Published var callParticipants = [CallParticipant]()
    
    public init(callInfo: IncomingCall) {
        self.callInfo = callInfo
        loadCallParticipants()
    }
    
    private func loadCallParticipants() {
        // TODO: fix this
//        Task {
//            do {
//                callParticipants = try await streamVideo.loadParticipants(for: callInfo)
//            } catch {
//                log.error("Error loading call participants")
//            }
//        }
    }
}
