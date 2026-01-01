//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ReplayKit

/// Handler that can be used in broadcast upload extension to support screensharing from the background.
open class BroadcastSampleHandler: RPBroadcastSampleHandler, @unchecked Sendable {

    /// Represents the client connection for uploading broadcast buffers.
    private var clientConnection: BroadcastBufferUploadConnection?

    /// Handles the uploading of broadcast buffers.
    private var uploader: BroadcastBufferUploader?

    /// Core Foundation notification center used for broadcasting notifications.
    private let notificationCenter: CFNotificationCenter

    private let disposableBag = DisposableBag()

    /// File path for the socket used in broadcasting.
    private var socketFilePath: String {
        guard let appGroupIdentifier = infoPlistValue(for: BroadcastConstants.broadcastAppGroupIdentifier),
              let sharedContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        else {
            return ""
        }

        return sharedContainer.appendingPathComponent(
            BroadcastConstants.broadcastSharePath
        )
        .path
    }

    /// Initializes the broadcast sample handler.
    override public init() {
        notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        super.init()

        if let connection = BroadcastBufferUploadConnection(filePath: socketFilePath) {
            clientConnection = connection
            setupConnection()
            uploader = BroadcastBufferUploader(connection: connection)
        }
    }

    /// Handles the broadcast start event.
    ///
    /// - Parameter setupInfo: Information passed during setup.
    override public func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        postNotification(BroadcastConstants.broadcastStartedNotification)
        openConnection()
    }

    /// Placeholder method for handling broadcast pause event.
    override public func broadcastPaused() {
        // No action required for broadcast pause
    }

    /// Placeholder method for handling broadcast resume event.
    override public func broadcastResumed() {
        // No action required for broadcast resume
    }

    /// Handles the broadcast end event.
    override public func broadcastFinished() {
        postNotification(BroadcastConstants.broadcastStoppedNotification)
        clientConnection?.close()
    }

    /// Processes the sample buffer.
    ///
    /// - Parameters:
    ///   - sampleBuffer: The sample buffer to process.
    ///   - sampleBufferType: The type of the sample buffer.
    override public func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        with sampleBufferType: RPSampleBufferType
    ) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            Task(disposableBag: disposableBag) { [weak uploader] in
                await uploader?.send(sample: sampleBuffer)
            }
        default:
            break
        }
    }

    // MARK: - Private Helpers

    /// Sets up the client connection and defines an `onClose` callback.
    private func setupConnection() {
        clientConnection?.onClose = { [weak self] error in
            if let error = error {
                self?.finishBroadcastWithError(error)
            } else {
                let screenshareError = NSError(
                    domain: RPRecordingErrorDomain,
                    code: 1001,
                    userInfo: [NSLocalizedDescriptionKey: "Screen sharing stopped"]
                )
                self?.finishBroadcastWithError(screenshareError)
            }
        }
    }

    /// Opens the broadcast connection using a timer.
    private func openConnection() {
        let queue = DispatchQueue(label: "broadcast.connectTimer")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: .milliseconds(100),
            leeway: .milliseconds(500)
        )
        timer.setEventHandler { [weak self] in
            guard self?.clientConnection?.open() == true else {
                return
            }

            timer.cancel()
        }

        timer.resume()
    }

    /// Posts a notification using Core Foundation's notification center.
    ///
    /// - Parameter name: The name of the notification to post.
    private func postNotification(_ name: String) {
        CFNotificationCenterPostNotification(
            notificationCenter,
            CFNotificationName(rawValue: name as CFString),
            nil,
            nil,
            true
        )
    }
}
