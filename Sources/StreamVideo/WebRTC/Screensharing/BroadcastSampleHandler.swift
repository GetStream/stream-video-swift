//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@preconcurrency import ReplayKit

open class BroadcastSampleHandler: RPBroadcastSampleHandler {
    
    private var clientConnection: BroadcastBufferUploadConnection?
    private var uploader: BroadcastBufferUploader?
    private let notificationCenter: CFNotificationCenter    
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
    
    public override init() {
        notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        super.init()
        
        if let connection = BroadcastBufferUploadConnection(filePath: self.socketFilePath) {
            self.clientConnection = connection
            self.setupConnection()
            self.uploader = BroadcastBufferUploader(connection: connection)
        }
    }
    
    override public func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        postNotification(BroadcastConstants.broadcastStartedNotification)
        self.openConnection()
    }
    
    override public func broadcastPaused() {}
    
    override public func broadcastResumed() {}
    
    override public func broadcastFinished() {
        postNotification(BroadcastConstants.broadcastStoppedNotification)
        clientConnection?.close()
    }
    
    override public func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            Task {
                await uploader?.send(sample: sampleBuffer)
            }
        default:
            break
        }
    }
    
    //MARK: - private
    
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
