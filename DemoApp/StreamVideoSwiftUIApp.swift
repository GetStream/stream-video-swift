//
//  StreamVideoSwiftUIApp.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

@main
struct StreamVideoSwiftUIApp: App {
    
    var streamVideo: StreamVideo
    
    init() {
        let video = StreamVideo(apiKey: "1234")
        streamVideo = video
        Task {
            do {
                let userInfo = UserInfo(id: "test", name: "Martin", imageURL: nil, extraData: [:])
                let token = try Token(rawValue: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidG9tbWFzbyJ9.XGkxJKi33fHr3cHyLFc6HRnbPgLuwNHuETWQ2MWzz5c")
                try await video.connectUser(userInfo: userInfo, token: token)
            } catch {
                print("error occurred")
            }

        }
    }
    
    var body: some Scene {
        WindowGroup {
            CallView()
        }
    }
    
}
