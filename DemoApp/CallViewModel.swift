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

class CallViewModel: ObservableObject {
    
    let room = ExampleObservableRoom()
    
    var shouldShowRoomView: Bool {
        room.room.connectionState.isConnected || room.room.connectionState.isReconnecting
    }
    
    @Published var shouldShowError: Bool = false
    public var latestError: Error?
    
    private let url: String = "wss://livekit.fucking-go-slices.com"
    
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
    
    init() {
        room.room.add(delegate: self)
    }
    
    func test() {
        Task {
            let selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
            let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
            print(response)
        }
    }
    
    func connect() -> Promise<Room> {
        if selectedUser == nil {
            selectedUser = users.first
        }

        let connectOptions = ConnectOptions(
            autoSubscribe: true,
            publishOnlyMode: nil
        )

        let roomOptions = RoomOptions(
            defaultScreenShareCaptureOptions: ScreenShareCaptureOptions(
            ),
            // Pass the simulcast option
            defaultVideoPublishOptions: VideoPublishOptions(
                simulcast: true
            ),
            adaptiveStream: false,
            dynacast: false,
            reportStats: false
        )

        return room.room.connect(url,
                                 selectedUser!.token,
                                 connectOptions: connectOptions,
                                 roomOptions: roomOptions)
    }
    
}

extension CallViewModel: RoomDelegate {

    func room(_ room: Room, didUpdate connectionState: ConnectionState, oldValue: ConnectionState) {

        print("Did update connectionState \(connectionState) \(room.connectionState)")

        if let error = connectionState.disconnectedWithError {
            latestError = error
            DispatchQueue.main.async {
                self.shouldShowError = true
            }
        }

        DispatchQueue.main.async {
            withAnimation {
                self.objectWillChange.send()
            }
        }
    }
}



struct User: Identifiable, Equatable {
    let name: String
    let token: String
    var id: String {
        name
    }
}
