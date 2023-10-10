//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import NukeUI
import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallsView: View {
            
    @StateObject var viewModel: DemoCallsViewModel
    
    init(callViewModel: CallViewModel) {
        _viewModel = StateObject(wrappedValue: DemoCallsViewModel(callViewModel: callViewModel))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if viewModel.favorites.count > 0 {
                    Text("Favorites")
                        .font(.headline)
                    ForEach(viewModel.favorites) { employee in
                        StreamEmployeeView(viewModel: viewModel, employee: employee)
                    }
                }
                
                Text("Stream employees")
                    .font(.headline)
                ForEach(viewModel.streamEmployees) { employee in
                    StreamEmployeeView(viewModel: viewModel, employee: employee)
                }
            }
            .padding()
        }
        .onAppear {
            viewModel.loadEmployees()
        }
        .navigationTitle("Stream Calls")
    }
}

struct StreamEmployeeView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: DemoCallsViewModel
    var employee: StreamEmployee
    
    var body: some View {
        HStack {
            LazyImage(imageURL: employee.imageURL)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            Text(employee.name)
            Spacer()
            
            Button(action: {
                viewModel.startCall(with: employee)
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Image(systemName: "phone.fill")
            })
            
            Button(action: {
                viewModel.favoriteTapped(for: employee)
            }, label: {
                Image(systemName: employee.isFavorite ? "star.fill" : "star")
            })
        }
    }
}
