//
//  CallViewModel.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 29.6.22.
//

import SwiftUI
import Combine
import LiveKit
import Promises

@MainActor
class CallViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published var room: VideoRoom? {
        didSet {
            room?.$connectionStatus
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] status in
                    self?.shouldShowRoomView = status == .connected || status == .reconnecting
            })
            .store(in: &cancellables)
        }
    }
    
    @Published var shouldShowRoomView: Bool = false
    
    @Published var shouldShowError: Bool = false
    public var latestError: Error?
    
    private var url: String = "wss://livekit.fucking-go-slices.com"
    private var cancellables = Set<AnyCancellable>()
    
    @Published var users = [
        User(
            name: "User 1",
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTkwMjI0NjEsImlzcyI6IkFQSVM0Y2F6YXg5dnFRUSIsIm5iZiI6MTY1NjQzMDQ2MSwic3ViIjoicm9iIiwidmlkZW8iOnsicm9vbSI6InN0YXJrLXRvd2VyIiwicm9vbUpvaW4iOnRydWV9fQ.vKC-RXDSYGqeyChwazQLO15mV1S1n4LxyeJLrJASYPA"),
        User(
            name: "User 2",
            token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTkwMjI1MzMsImlzcyI6IkFQSVM0Y2F6YXg5dnFRUSIsIm5iZiI6MTY1NjQzMDUzMywic3ViIjoiYm9iIiwidmlkZW8iOnsicm9vbSI6InN0YXJrLXRvd2VyIiwicm9vbUpvaW4iOnRydWV9fQ.XTQ9nU5BJ3FdWUaOrge-u977YibNTfK-sTDRaI0_vRc")
    ]
    
    @Published var selectedUser: User?
    
    let callCoordinatorService = Stream_Video_CallCoordinatorService(
        hostname: "http://localhost:26991",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidG9tbWFzbyJ9.XGkxJKi33fHr3cHyLFc6HRnbPgLuwNHuETWQ2MWzz5c"
    )

    func selectEdgeServer() {
        Task {
            let selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
            let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
            url = "wss://\(response.edgeServer.url)"
        }
    }
    
    func makeCall() async throws {
        if selectedUser == nil {
            selectedUser = users.first
        }
        
        let token = selectedUser?.token ?? ""

        room = try await streamVideo.connect(url: url, token: token, options: VideoOptions())
    }
    
}

struct User: Identifiable, Equatable {
    let name: String
    let token: String
    var id: String {
        name
    }
}
