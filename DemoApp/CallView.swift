//
//  CallView.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 29.6.22.
//

import SwiftUI

struct CallView: View {
    
    @StateObject var viewModel = CallViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.shouldShowRoomView {
                RoomView(viewModel: viewModel)
            } else {
                ConnectView(viewModel: viewModel)
                    .onAppear() {
                        viewModel.selectEdgeServer()
                    }
            }

        }
    }
}

struct ConnectView: View {
    
    @ObservedObject var viewModel: CallViewModel
    
    var body: some View {
        VStack {
            ForEach(viewModel.users) { user in
                Button {
                    viewModel.selectedUser = user
                } label: {
                    Text(user.name)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(viewModel.selectedUser == user ? Color.gray.opacity(0.5) : nil)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            
            Spacer()
            
            Button {
                _ = viewModel.connect()
            } label: {
                Text("Start a call")
            }
            .disabled(viewModel.selectedUser == nil)
            
            Spacer()
        }
    }
    
}
