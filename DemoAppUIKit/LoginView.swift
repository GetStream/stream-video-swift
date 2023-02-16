//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideoSwiftUI
import SwiftUI

//TODO: Re-implement in UIKit.
struct LoginView: View {
    
    @BackportStateObject var viewModel: LoginViewModel
    var completion: (UserCredentials) -> ()
    
    @State var addUserShown = false
    
    init(completion: @escaping (UserCredentials) -> ()) {
        self.completion = completion
        _viewModel = BackportStateObject(wrappedValue: LoginViewModel())
    }
    
    var body: some View {
        VStack {
            Text("Select a user")
                .font(.title)
                .bold()
            List(viewModel.userCredentials) { user in
                Button {
                    viewModel.login(user: user, completion: completion)
                } label: {
                    Text(user.userInfo.name)
                        .accessibility(identifier: "userName")
                }
                .padding(.all, 8)
            }
         
            Button {
                addUserShown = true
            } label: {
                Text("Add user")
                    .padding()
            }
            .foregroundColor(Color.white)
            .background(Color.blue)
            .cornerRadius(16)
        }
        .foregroundColor(.primary)
        .sheet(isPresented: $addUserShown, onDismiss: {
            viewModel.userCredentials = UserCredentials.builtInUsers
        }) {
            AddUserView()
        }
    }
}
