//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamVideo
import StreamVideoSwiftUI
import SwiftUI
import ReplayKit

struct CallControlsView_iPad: View {
    
    @Injected(\.streamVideo) var streamVideo
        
    private let size: CGFloat = 50
    
    @ObservedObject var viewModel: CallViewModel
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        EqualSpacingHStack {
            [
                VideoIconView(viewModel: viewModel).asAnyView,
                MicrophoneIconView(viewModel: viewModel).asAnyView,
                ToggleCameraIconView(viewModel: viewModel).asAnyView,
                ScreenshareIconView(viewModel: viewModel).asAnyView,
                BroadcastIconView(viewModel: viewModel).asAnyView,
                HangUpIconView(viewModel: viewModel).asAnyView
            ]
        }
        .frame(maxWidth: .infinity)
        .frame(height: 85)
        .background(
            colors.callControlsBackground
                .edgesIgnoringSafeArea(.all)
        )
        .overlay(
            VStack {
                colors.callControlsBackground
                    .frame(height: 30)
                    .cornerRadius(24)
                Spacer()
            }
            .offset(y: -15)
        )
    }
}

public struct ScreenshareIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: CallViewModel
    let size: CGFloat
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        Button {
            viewModel.startScreensharing(type: .inApp)
        } label: {
            CallIconView(
                icon: Image(systemName: "square.and.arrow.up.circle.fill"),
                size: size,
                iconStyle: (viewModel.call?.state.isCurrentUserScreensharing == false ? .primary : .transparent)
            )
        }
    }
}

public struct BroadcastIconView: View {
    
    @Injected(\.images) var images
    @Injected(\.colors) var colors
    
    @ObservedObject var viewModel: CallViewModel
    @StateObject var broadcastObserver = BroadcastObserver()
    let size: CGFloat
    let iconStyle = CallIconStyle.primary
    let iconSize: CGFloat = 50
    
    public init(viewModel: CallViewModel, size: CGFloat = 50) {
        self.viewModel = viewModel
        self.size = size
    }
    
    public var body: some View {
        ZStack(alignment: .center) {
            Circle().fill(
                iconStyle.backgroundColor.opacity(iconStyle.opacity)
            )
            BroadcastPickerView(
                preferredExtension: "io.getstream.iOS.VideoDemoApp.ScreenSharing",
                size: iconSize
            )
            .frame(width: iconSize, height: iconSize)
            .offset(x: -5, y: -4)
            .foregroundColor(iconStyle.foregroundColor)
        }
        .frame(width: size, height: size)
        .onChange(of: broadcastObserver.broadcastState, perform: { newValue in
            if newValue == .started {
                viewModel.startScreensharing(type: .broadcast)
            } else if newValue == .finished {
                viewModel.stopScreensharing()
                broadcastObserver.broadcastState = .notStarted
            }
        })
        .onAppear {
            broadcastObserver.observe()
        }
    }
}

enum BroadcastState {
    case notStarted
    case started
    case finished
}

private let broadcastStartedNotification = "iOS_BroadcastStarted"
private let broadcastStoppedNotification = "iOS_BroadcastStopped"

class BroadcastObserver: ObservableObject {
    
    @Published var broadcastState: BroadcastState = .notStarted
    
    lazy var broadcastStarted: CFNotificationCallback = { center, observer, name, object, userInfo in
        postNotification(with: broadcastStartedNotification)
    }
    
    lazy var broadcastStopped: CFNotificationCallback = { center, observer, name, object, userInfo in
        postNotification(with: broadcastStoppedNotification)
    }
    
    func observe() {
        observe(notification: broadcastStartedNotification, function: broadcastStarted)
        observe(notification: broadcastStoppedNotification, function: broadcastStopped)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBroadcastStarted),
            name: NSNotification.Name(broadcastStartedNotification),
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBroadcastStopped),
            name: NSNotification.Name(broadcastStoppedNotification),
            object: nil
        )
    }
    
    private func observe(notification: String, function: CFNotificationCallback) {
        let cfstr = notification as CFString
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            notificationCenter,
            nil,
            function,
            cfstr,
            nil,
            .deliverImmediately
        )
    }

    @objc func handleBroadcastStarted() {
        self.broadcastState = .started
    }
    
    @objc func handleBroadcastStopped() {
        self.broadcastState = .finished
    }
}

struct EqualSpacingHStack: View {
    
    var views: () -> [AnyView]
    
    var body: some View {
        HStack(alignment: .top) {
            ForEach(0..<views().count, id:\.self) { index in
                Spacer()
                views()[index]
                Spacer()
            }
        }
    }
    
}

extension View {
    
    var asAnyView: AnyView {
        AnyView(self)
    }
    
}

//TODO: move from here
import ReplayKit

struct BroadcastPickerView: UIViewRepresentable {
    
    let preferredExtension: String
    var size: CGFloat = 30
    
    func makeUIView(context: Context) -> some UIView {
        let view = RPSystemBroadcastPickerView(frame: .init(x: 0, y: 0, width: size, height: size))
        view.preferredExtension = preferredExtension
        view.showsMicrophoneButton = false
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    
}

func postNotification(with name: String, userInfo: [AnyHashable: Any] = [:]) {
    NotificationCenter.default.post(name: NSNotification.Name(name), object: nil, userInfo: userInfo)
}
