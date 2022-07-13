//
//  LoginView.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 13.7.22.
//

import SwiftUI

struct LoginView: View {
    
    @StateObject var viewModel: LoginViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: LoginViewModel())
    }
    
    var body: some View {
        VStack {
            Text("Select a user")
                .font(.title)
                .bold()
            List(viewModel.userCredentials) { user in
                Button {
                    viewModel.login(user: user)
                } label: {
                    Text(user.userInfo.name ?? user.userInfo.id)
                }
                .padding(.all, 8)
            }
        }
        .foregroundColor(.primary)
        .overlay(
            viewModel.loading ? ProgressView() : nil
        )
    }
}
