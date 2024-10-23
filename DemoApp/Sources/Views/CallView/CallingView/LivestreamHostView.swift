import SwiftUI
import StreamVideo
import StreamVideoSwiftUI

struct LivestreamHostView: View {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Environment(\.presentationMode) var presentationMode

    @State var call: Call
    @StateObject var state: CallState

    let formatter = DateComponentsFormatter()
    
    init(
        type: String,
        id: String
    ) {
        let call = InjectedValues[\.streamVideo].call(callType: type, callId: id)
        self.call = call
        _state = StateObject(wrappedValue: call.state)
        formatter.unitsStyle = .full
    }
    
    var duration: String? {
        guard call.state.duration > 0  else { return nil }
        return formatter.string(from: call.state.duration)
    }
    
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .padding(.leading)
                Spacer()
            }
            
            HStack {
                if let duration {
                    Text("Live for \(duration)")
                        .font(.headline)
                        .padding(.horizontal)
                }

                Spacer()

                Text("Live \(state.participantCount)")
                    .bold()
                    .padding(.all, 4)
                    .padding(.horizontal, 2)
                    .foregroundColor(.white)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .opacity(call.state.backstage ? 0 : 1)
                    .padding(.horizontal)
            }

            GeometryReader { reader in
                if let first = state.participants.first {
                    VideoRendererView(id: first.id, size: reader.size) { renderer in
                        renderer.handleViewRendering(for: first) { size, participant in }
                    }
                } else {
                    Color(UIColor.secondarySystemBackground)
                }
            }
            .padding()

            ZStack {
                if call.state.backstage {
                    Button {
                        Task {
                            try await call.goLive()
                        }
                    } label: {
                        Text("Go Live")
                    }
                } else {
                    Button {
                        Task {
                            try await call.stopLive()
                        }
                    } label: {
                        Text("Stop Livestream")
                    }
                }
            }
            .padding()
        }
        .background(Color(UIColor.systemBackground))
        .navigationBarHidden(true)
        .onAppear {
            Task {
                try await call.join(create: true)
            }
        }
        .onDisappear {
            call.leave()
        }
    }
}
