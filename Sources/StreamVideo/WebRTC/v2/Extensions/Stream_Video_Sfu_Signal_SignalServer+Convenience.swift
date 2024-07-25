//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Signal_SignalServer {

    convenience init(
        apiKey: String,
        hostname: String,
        token: String,
        httpClient: HTTPClient = URLSessionClient(
            urlSession: StreamVideo.Environment.makeURLSession()
        )
    ) {
        self.init(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token
        )
    }
}
