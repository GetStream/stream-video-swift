//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
import StreamVideo

struct AddUserView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State var name = ""
    @State var id = ""
    @State var token = ""
    
    var body: some View {
        VStack {
            Text("Add a new user")
                .font(.title)
                .padding()
            
            TextField("User id", text: $id)
                .textFieldStyle(.roundedBorder)
                .padding(.all, 8)
            
            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .padding(.all, 8)
            
            TextField("Token", text: $token)
                .textFieldStyle(.roundedBorder)
                .padding(.all, 8)
            
            Button {
                let userInfo = User(
                    id: id,
                    name: name,
                    imageURL: nil,
                    customData: [:]
                )
                AppState.shared.users.append(userInfo)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("Add user")
                    .padding()
            }
            .foregroundColor(Color.white)
            .background(buttonDisabled ? Color.gray : Color.blue)
            .disabled(buttonDisabled)
            .cornerRadius(16)

            Spacer()
        }
    }
    
    private var buttonDisabled: Bool {
        name.isEmpty || id.isEmpty || token.isEmpty
    }
    
}
