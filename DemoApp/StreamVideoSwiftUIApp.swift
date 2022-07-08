//
//  StreamVideoSwiftUIApp.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import SwiftUI

@main
struct StreamVideoSwiftUIApp: App {
    
    var streamVideo: StreamVideo
    
    init() {
        streamVideo = StreamVideo(apiKey: "1234")
    }
    
    var body: some Scene {
        WindowGroup {
            CallView()
        }
    }
}

let mockUsers = [
    User(
        name: "User 1",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTkwMjI0NjEsImlzcyI6IkFQSVM0Y2F6YXg5dnFRUSIsIm5iZiI6MTY1NjQzMDQ2MSwic3ViIjoicm9iIiwidmlkZW8iOnsicm9vbSI6InN0YXJrLXRvd2VyIiwicm9vbUpvaW4iOnRydWV9fQ.vKC-RXDSYGqeyChwazQLO15mV1S1n4LxyeJLrJASYPA"),
    User(
        name: "User 2",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTkwMjI1MzMsImlzcyI6IkFQSVM0Y2F6YXg5dnFRUSIsIm5iZiI6MTY1NjQzMDUzMywic3ViIjoiYm9iIiwidmlkZW8iOnsicm9vbSI6InN0YXJrLXRvd2VyIiwicm9vbUpvaW4iOnRydWV9fQ.XTQ9nU5BJ3FdWUaOrge-u977YibNTfK-sTDRaI0_vRc")
]
