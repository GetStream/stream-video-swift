//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI

struct DemoCallsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject var viewModel: DemoCallsViewModel
    
    init(callViewModel: CallViewModel) {
        _viewModel = StateObject(wrappedValue: DemoCallsViewModel(callViewModel: callViewModel))
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if !viewModel.favorites.isEmpty {
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
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.groupCallParticipants.isEmpty {
                    Button(action: {
                        viewModel.startCall(with: viewModel.groupCallParticipants)
                        viewModel.groupCallParticipants = []
                        presentationMode.wrappedValue.dismiss()
                    }, label: {
                        Text("Call the group")
                    })
                } else {
                    Button(action: {
                        viewModel.groupCall.toggle()
                    }, label: {
                        Text("Group Call")
                    })
                }
            }
        })
    }
}

struct StreamEmployeeView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var viewModel: DemoCallsViewModel
    var employee: StreamEmployee
    
    var body: some View {
        HStack {
            StreamLazyImage(imageURL: employee.imageURL)
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            Text(employee.name)
            Spacer()
            
            if viewModel.groupCall {
                Button(action: {
                    viewModel.groupSelectionTapped(for: employee)
                }, label: {
                    Image(
                        systemName: viewModel.groupCallParticipants.contains(employee) ? "checkmark.circle.fill" : "circle"
                    )
                })
            }
            
            Button(action: {
                viewModel.startCall(with: [employee])
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
        .id("\(employee.id)-\(employee.isFavorite)")
    }
}
