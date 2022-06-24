//
//  HomeView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject var viewModel: HomeViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: ViewModelFactory.shared.makeHomeViewModel())
    }
    
    var body: some View {
        NavigationView {
            VStack {
                InfoView(key: "Signalling status:", title: viewModel.signallingStatus)
                InfoView(key: "Local SDP:", title: viewModel.localSDP ? "✅" : "❌")
                InfoView(key: "Local candidates:", title: "\(viewModel.localCandidates)")
                InfoView(key: "Remote SDP:", title: viewModel.remoteSDP ? "✅" : "❌")
                InfoView(key: "Remote candidates:", title: "\(viewModel.remoteCandidates)")
                InfoView(key: "WebRTC Status:", title: viewModel.webRTCStatus)
                
                Spacer()
                
                Button {
                    viewModel.sendOffer()
                } label: {
                    Text("Send offer")
                }
                .padding()

                Button {
                    viewModel.sendAnswer()
                } label: {
                    Text("Send answer")
                }
                .padding()
                
                NavigationLink {
                    VideoView()
                } label: {
                    Text("Show video")
                }
                .padding()
            }
            .navigationTitle("WebRTC Demo")
        }        
    }
}

struct InfoView: View {
    
    var key: String
    var title: String
    
    var body: some View {
        HStack {
            Text(key)
            Text(title)
            Spacer()
        }
        .padding()
    }
    
}
