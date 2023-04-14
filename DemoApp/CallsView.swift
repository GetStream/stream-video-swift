//
//  CallsView.swift
//  DemoApp
//
//  Created by Martin Mitrevski on 13.4.23.
//

import SwiftUI

struct CallsView: View {
    
    @StateObject var viewModel = CallsViewModel()
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(viewModel.calls) { call in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(call.callCid)
                                .bold()
                            Text("\(call.members.map(\.id).joined(separator: ","))")
                                .font(.caption)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            if !call.backstage {
                                Text("Live")
                                    .bold()
                                    .foregroundColor(.green)
                            }
                            if #available(iOS 15, *) {
                                Text(call.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .onAppear {
                        viewModel.onCallAppear(call)
                    }
                }
            }
        }
    }
}
