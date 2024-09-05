//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class SFUSignalService {
    private let signalServer: Stream_Video_Sfu_Signal_SignalServer

    let subject: PassthroughSubject<SignalServerEvent, Never> = .init()

    init(signalServer: Stream_Video_Sfu_Signal_SignalServer) {
        self.signalServer = signalServer
    }
}
