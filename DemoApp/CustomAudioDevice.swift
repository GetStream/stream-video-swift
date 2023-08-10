import Foundation
import WebRTC
import AVFoundation

final class AUAudioUnitRTCAudioDevice: NSObject {
  let audioSession = AVAudioSession.sharedInstance()
  private let queue = DispatchQueue(label: "AUAudioUnitRTCAudioDevice")

  private var audioUnit: AUAudioUnit?
  private var audioUnitRenderBlock: AURenderBlock?
  private var subscribtions: [Any]?
  private var shouldPlay = false
  private var shouldRecord = false

  private var isInterrupted_ = false
  private var isInterrupted: Bool {
    get {
      queue.sync {
        isInterrupted_
      }
    }
    set {
      queue.sync {
        isInterrupted_ = newValue
      }
    }
  }

  var delegate_: RTCAudioDeviceDelegate?
  private var delegate: RTCAudioDeviceDelegate? {
    get {
      queue.sync {
        delegate_
      }
    }
    set {
      queue.sync {
        delegate_ = newValue
      }
    }
  }

  private lazy var audioInputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                                    sampleRate: audioSession.sampleRate,
                                                    channels: AVAudioChannelCount(min(2, audioSession.inputNumberOfChannels)),
                                                    interleaved: true) {
    didSet {
      guard oldValue != audioInputFormat else { return }
      delegate?.notifyAudioInputParametersChange()
    }
  }

  private lazy var audioOutputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                                     sampleRate: audioSession.sampleRate,
                                                     channels: AVAudioChannelCount(min(2, audioSession.outputNumberOfChannels)),
                                                     interleaved: true) {
    didSet {
      guard oldValue != audioOutputFormat else { return }
      delegate?.notifyAudioOutputParametersChange()
    }
  }

  private (set) lazy var inputLatency = audioSession.inputLatency {
    didSet {
      guard oldValue != inputLatency else { return }
      delegate?.notifyAudioInputParametersChange()
    }
  }
  
  private (set) lazy var outputLatency = audioSession.outputLatency {
    didSet {
      guard oldValue != outputLatency else { return }
      delegate?.notifyAudioOutputParametersChange()
    }
  }

  override init() {
    super.init()
  }

  private func updateAudioUnit() {
    guard let audioUnit = audioUnit else {
      return
    }

    audioUnit.dumpState(label: "Before audio unit update")

    let stopAudioUnit = { (label: String) in
      if audioUnit.isRunning {
        measureTime(label: "AVAudioUnit stop hardware to \(label)") {
          audioUnit.stopHardware()
          guard let delegate = self.delegate else {
            return
          }
          delegate.notifyAudioInputInterrupted()
          delegate.notifyAudioOutputInterrupted()
        }
      }
    }

    let stopAndUnitializeAudioUnit = { (label: String) in
      stopAudioUnit(label)
      if audioUnit.renderResourcesAllocated {
        measureTime(label: "AVAudioUnit deallocate render resources to \(label)") {
          audioUnit.deallocateRenderResources()
        }
      }
    }

    guard let delegate = delegate, shouldPlay || shouldRecord, !isInterrupted else {
      stopAndUnitializeAudioUnit("turn off audio unit")
      return
    }

    if audioUnit.isInputEnabled != shouldRecord {
      stopAndUnitializeAudioUnit("toggle input")
      measureTime(label: "AVAudioUnit toggle input") {
        audioUnit.isInputEnabled = shouldRecord
      }
    }

    if audioUnit.isOutputEnabled != shouldPlay {
      stopAndUnitializeAudioUnit("toggle output")
      measureTime(label: "AVAudioUnit toggle output") {
        audioUnit.isOutputEnabled = shouldPlay
      }
    }
    

    let hardwareSampleRate = audioSession.sampleRate
    if shouldRecord {
      let rtcRecordFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: hardwareSampleRate,
        channels: AVAudioChannelCount(min(2, audioSession.inputNumberOfChannels)),
        interleaved: true)!

      let bus = 1
      let outputBus = audioUnit.outputBusses[bus]
      if outputBus.format != rtcRecordFormat {
        stopAndUnitializeAudioUnit("Stop to update recording format of audioUnit.outputBusses[\(bus)]")
        measureTime(label: "Update recording format of audioUnit.outputBusses[\(bus)]") {
          do {
            try outputBus.setFormat(rtcRecordFormat)
            print("Record format set to: \(rtcRecordFormat)")
          } catch let e {
            print("Failed update audioUnit.outputBusses[\(bus)].format of audio unit: \(e)")
            return
          }
        }
      }
      audioInputFormat = rtcRecordFormat

      measureTime(label: "AVAudioUnit define inputHandler") {
        let deliverRecordedData = delegate.deliverRecordedData
        let renderBlock = audioUnit.renderBlock
        let customRenderBlock: RTCAudioDeviceRenderRecordedDataBlock = { actionFlags, timestamp, inputBusNumber, frameCount, abl, renderContext in
          return renderBlock(actionFlags, timestamp, frameCount, inputBusNumber, abl, nil)
        }
        audioUnit.inputHandler = { actionFlags, timestamp, frameCount, inputBusNumber in
          let status = deliverRecordedData(actionFlags, timestamp, inputBusNumber, frameCount, nil, nil, customRenderBlock)
          if status != noErr {
            print("Failed to deliver audio data: \(status)")
          }
        }
      }
      inputLatency = audioSession.inputLatency
    }
  
    if shouldPlay {
      let rtcPlayFormat = AVAudioFormat(
        commonFormat: .pcmFormatInt16,
        sampleRate: hardwareSampleRate,
        channels: AVAudioChannelCount(min(2, audioSession.outputNumberOfChannels)),
        interleaved: true)!
      let bus = 0;
      let inputBus = audioUnit.inputBusses[bus]
      if inputBus.format != rtcPlayFormat {
        stopAndUnitializeAudioUnit("Stop to update recording format of audioUnit.outputBusses[\(bus)]")
        measureTime(label: "Update playout format of audioUnit.inputBusses[\(bus)]") {
          do {
            try inputBus.setFormat(rtcPlayFormat)
            print("Play format set to: \(rtcPlayFormat)")
          } catch let e {
            print("Failed update audioUnit.inputBusses[\(bus)].format of audio unit: \(e)")
            return
          }
        }
      }
      audioOutputFormat = rtcPlayFormat

      if audioUnit.outputProvider == nil {
        measureTime(label: "AVAudioUnit define outputProvider") {
          let getPlayoutData = delegate.getPlayoutData
          // NOTE: No need to stop or unitialized AU before change property
          audioUnit.outputProvider = { (actionFlags, timestamp, frameCount, inputBusNumber, inputData) -> AUAudioUnitStatus in
            return getPlayoutData(actionFlags, timestamp, inputBusNumber, frameCount, inputData)
          }
        }
      }
      outputLatency = audioSession.outputLatency
    }

    if !audioUnit.renderResourcesAllocated {
      measureTime(label: "AVAudioUnit allocate render resources") {
        do {
          try audioUnit.allocateRenderResources()
        }
        catch let e {
          print("allocateRenderResources error: \(e)")
          return
        }
      }
    }
    if !audioUnit.isRunning {
      measureTime(label: "AVAudioUnit start hardware") {
        do {
          try audioUnit.startHardware()
        }
        catch let e {
          print("startHardware error: \(e)")
          return
        }
      }
    }
    audioUnit.dumpState(label: "After audio unit update")
  }
}


extension AUAudioUnitRTCAudioDevice: RTCAudioDevice {

  var deviceInputSampleRate: Double {
    guard let sampleRate = audioInputFormat?.sampleRate, sampleRate > 0 else {
      return audioSession.sampleRate
    }
    return sampleRate
  }

  var deviceOutputSampleRate: Double {
    guard let sampleRate = audioOutputFormat?.sampleRate, sampleRate > 0 else {
      return audioSession.sampleRate
    }
    return sampleRate
  }

  var inputIOBufferDuration: TimeInterval { audioSession.ioBufferDuration }

  var outputIOBufferDuration: TimeInterval { audioSession.ioBufferDuration }

  var inputNumberOfChannels: Int {
    guard let channelCount = audioInputFormat?.channelCount, channelCount > 0 else {
      return min(2, audioSession.inputNumberOfChannels)
    }
    return Int(channelCount)
  }

  var outputNumberOfChannels: Int {
    guard let channelCount = audioOutputFormat?.channelCount, channelCount > 0 else {
      return min(2, audioSession.outputNumberOfChannels)
    }
    return Int(channelCount)
  }

  var isInitialized: Bool {
    delegate != nil && audioUnit != nil
  }

  func initialize(with delegate: RTCAudioDeviceDelegate) -> Bool {
    guard self.delegate == nil else {
      return false
    }

    let description = AudioComponentDescription(
      componentType: kAudioUnitType_Output,
      componentSubType: audioSession.supportsVoiceProcessing ? kAudioUnitSubType_VoiceProcessingIO : kAudioUnitSubType_RemoteIO,
      componentManufacturer: kAudioUnitManufacturer_Apple,
      componentFlags: 0,
      componentFlagsMask: 0);
    
    let audioUnit: AUAudioUnit
    do {
      audioUnit = try AUAudioUnit.init(componentDescription: description)
    } catch let e {
      print("Failed init audio unit: \(e)")
      return false
    }
    audioUnit.isInputEnabled = false
    audioUnit.isOutputEnabled = false
    audioUnit.maximumFramesToRender = 1024
    
    if subscribtions == nil {
      subscribtions = subscribeAudioSessionNotifications()
    }
    if !audioSession.supportsVoiceProcessing {
      configureStereoRecording()
    }
    
    self.audioUnit = audioUnit
    self.delegate = delegate
    return true
  }

  func terminateDevice() -> Bool {
    if let subscribtions = subscribtions {
      unsubscribeAudioSessionNotifications(observers: subscribtions)
    }
    subscribtions = nil

    shouldPlay = false
    shouldRecord = false
    updateAudioUnit()

    audioUnit = nil
    return true
  }

  var isPlayoutInitialized: Bool {
    isInitialized
  }

  func initializePlayout() -> Bool {
    return isPlayoutInitialized
  }

  var isPlaying: Bool {
    self.shouldPlay
  }

  func startPlayout() -> Bool {
    shouldPlay = true
    updateAudioUnit()
    
    return true
  }
  
  func stopPlayout() -> Bool {
    shouldPlay = false
    updateAudioUnit()
 
    return true
  }
  
  var isRecordingInitialized: Bool {
    isInitialized
  }

  func initializeRecording() -> Bool {
    isRecordingInitialized
  }

  var isRecording: Bool {
    shouldRecord
  }
  
  func startRecording() -> Bool {
    shouldRecord = true
    updateAudioUnit()
    return true
  }
  
  func stopRecording() -> Bool {
    shouldRecord = false
    updateAudioUnit()
    return true
  }
}

extension AUAudioUnitRTCAudioDevice: AudioSessionHandler {
  func handleInterruptionBegan(applicationWasSuspended: Bool) {
    guard !applicationWasSuspended else {
      // NOTE: Not an actual interruption
      return
    }
    self.isInterrupted = true
    guard let delegate = delegate else {
      return
    }
    delegate.dispatchAsync {
      measureTime {
        self.updateAudioUnit()
      }
    }
  }
  
  func handleInterruptionEnd(shouldResume: Bool) {
    self.isInterrupted = false
    guard let delegate = delegate else {
      return
    }
    delegate.dispatchAsync {
      measureTime {
        self.updateAudioUnit()
      }
    }
  }

  func handleAudioRouteChange() {
    guard let delegate = delegate else {
      return
    }
    delegate.dispatchAsync {
      measureTime {
        self.updateAudioUnit()
      }
    }
  }
  
  func handleMediaServerWereReset() {
    guard let delegate = delegate else {
      return
    }
    delegate.dispatchAsync {
      measureTime {
        self.updateAudioUnit()
      }
    }
  }
  
  func handleMediaServerWereLost() {
  }
}

//
//  Utils.swift
//  CustomRTCAudioDevice
//
//  Created by Yury Yarashevich on 12.05.22.
//

import Foundation
import AVFoundation

extension DispatchTimeInterval: CustomDebugStringConvertible {
  public var debugDescription: String {
    switch self {
    case .seconds(let secs):
      return "\(secs) secs"
    case .milliseconds(let ms):
      return "\(ms) ms"
    case .microseconds(let us):
      return "\(Double(us) / 1000.0) ms"
    case .nanoseconds(let ns):
      return "\(Double(ns) / 1_000_000.0) ms"
    case .never:
      return "never"
    @unknown default:
      return ""
    }
  }
}

func measureTime<Result>(label: String = #function, block: () -> Result) -> Result {
  let start = DispatchTime.now()
  let result = block()
  let end = DispatchTime.now()
  let duration = start.distance(to: end)
  print("Executed \(label) within \(duration.debugDescription)")
  return result
}

func getBuffer(fileURL: URL) -> AVAudioPCMBuffer? {
  let file: AVAudioFile!
  do {
    try file = AVAudioFile(forReading: fileURL)
  } catch {
    print("Could not load file: \(error)")
    return nil
  }
  file.framePosition = 0
  
  // Add 100 ms to the capacity.
  let bufferCapacity = AVAudioFrameCount(file.length)
  + AVAudioFrameCount(file.processingFormat.sampleRate * 0.1)
  guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                      frameCapacity: bufferCapacity) else { return nil }
  do {
    try file.read(into: buffer)
  } catch {
    print("Could not load file into buffer: \(error)")
    return nil
  }
  file.framePosition = 0
  return buffer
}

extension AVAudioSession {

  var supportsVoiceProcessing: Bool {
    self.category == .playAndRecord && (self.mode == .voiceChat || self.mode == .videoChat)
  }

  var describedState: String {
    var description = "AudioSession: category=\(self.category.rawValue)" +
      ", mode=\(self.mode.rawValue)" +
      ", options=\(self.categoryOptions.rawValue)" +
      ", preferredSampleRate=\(self.preferredSampleRate)" +
      ", sampleRate=\(self.sampleRate)" +
      ", preferredIOBufferDuration=\(self.preferredIOBufferDuration)" +
      ", ioBufferDuration=\(self.ioBufferDuration)" +
      ", preferredInputNumberOfChannels=\(self.preferredInputNumberOfChannels)" +
      ", isInputAvailable=\(self.isInputAvailable)" +
      ", inputNumberOfChannels=\(self.inputNumberOfChannels)" +
      ", maximumInputNumberOfChannels=\(self.maximumInputNumberOfChannels)" +
      ", preferredOutputNumberOfChannels=\(self.preferredOutputNumberOfChannels)" +
      ", outputNumberOfChannels=\(self.outputNumberOfChannels)" +
      ", maximumOutputNumberOfChannels=\(self.maximumOutputNumberOfChannels)" +
      ", allowHapticsAndSystemSoundsDuringRecording=\(self.allowHapticsAndSystemSoundsDuringRecording)"

    if #available(iOS 14.5, *) {
      description += ", prefersNoInterruptionsFromSystemAlerts=\(self.prefersNoInterruptionsFromSystemAlerts)"
    }
    description +=
      ", currentRoute=\(self.currentRoute)"
    return description
  }
}

extension AVAudioEngine {
  func dumpState(label: String) {
    print("\(label): \(self.debugDescription)")
  }
  
  func isInputOutputSampleRatesNativeFor(audioSession: AVAudioSession) -> Bool {
    let hardwareSampleRate = audioSession.sampleRate
    let inputSampleRate = self.inputNode.inputFormat(forBus: 1).sampleRate
    let outputSampleRate = self.outputNode.outputFormat(forBus: 0).sampleRate
    return inputSampleRate == hardwareSampleRate && outputSampleRate == hardwareSampleRate
  }
  
  func isInputOutputSampleRatesWorseThan(audioSession: AVAudioSession) -> Bool {
    let hardwareSampleRate = audioSession.sampleRate
    let inputSampleRate = self.inputNode.inputFormat(forBus: 1).sampleRate
    let outputSampleRate = self.outputNode.outputFormat(forBus: 0).sampleRate
    return inputSampleRate < hardwareSampleRate && outputSampleRate < hardwareSampleRate
  }
}

extension AUAudioUnit {
  func dumpState(label: String) {
    print("\(label): audioUnit.inputBusses[0].format = \(self.inputBusses[0].format)")
    print("\(label): audioUnit.inputBusses[1].format = \(self.inputBusses[1].format)")
    print("\(label): audioUnit.outputBusses[0].format = \(self.outputBusses[0].format)")
    print("\(label): audioUnit.outputBusses[1].format = \(self.outputBusses[1].format)")
  }
}

extension AVAudioFormat {
  var isSampleRateAndChannelCountValid: Bool {
    !sampleRate.isZero && !sampleRate.isNaN && sampleRate.isFinite && channelCount > 0
  }
}

import Foundation
import AVFAudio

protocol AudioSessionHandler: AnyObject {
  var audioSession: AVAudioSession { get }
  
  func handleInterruptionBegan(applicationWasSuspended: Bool)
  
  func handleInterruptionEnd(shouldResume: Bool)
  
  func handleAudioRouteChange()
  
  func handleMediaServerWereReset()
  
  func handleMediaServerWereLost()
}

extension AudioSessionHandler {
  func subscribeAudioSessionNotifications() -> [Any] {
    let center = NotificationCenter.default
    let interruptionNotificationSubscribtion = center.addObserver(forName: AVAudioSession.interruptionNotification,
                                                                  object: audioSession,
                                                                  queue: nil) { [weak self] notification in
      guard let self = self else {
        return
      }
      print(AVAudioSession.interruptionNotification)
      guard let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber,
            let interruptionType: AVAudioSession.InterruptionType = .init(rawValue: type.uintValue) else {
        print("Ignoring \(notification)")
        return
      }
      switch interruptionType {
      case .began:
        var applicationWasSuspended: Bool = false
        if #available(iOS 14.5, *) {
          if let rawReason = notification.userInfo?[AVAudioSessionInterruptionReasonKey] as? NSNumber,
             let reason: AVAudioSession.InterruptionReason = .init(rawValue: rawReason.uintValue) {
            applicationWasSuspended = reason == .appWasSuspended
          }
        } else {
          if let wasSuspended = notification.userInfo?[AVAudioSessionInterruptionWasSuspendedKey] as? NSNumber, wasSuspended.boolValue {
            applicationWasSuspended = true
          }
        }
        self.handleInterruptionBegan(applicationWasSuspended: applicationWasSuspended)
      case .ended:
        var shouldResume = false
        if let type = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? NSNumber {
          let interruptionOptions: AVAudioSession.InterruptionOptions = .init(rawValue: type.uintValue)
          shouldResume = interruptionOptions.contains(.shouldResume)
        }
        self.handleInterruptionEnd(shouldResume: shouldResume)
      @unknown default:
        return
      }
      
    }
    let routeChangeNotificationSubscribtion = center.addObserver(forName: AVAudioSession.routeChangeNotification,
                                                                 object: audioSession,
                                                                 queue: nil) { [weak self] notification in
      guard let self = self else {
        return
      }
      print("\(AVAudioSession.routeChangeNotification): \(notification) -> \(self.audioSession.describedState)")
      self.handleAudioRouteChange()
    }
    
    let mediaServicesWereLostNotificationSubscribtion = center.addObserver(forName: AVAudioSession.mediaServicesWereLostNotification,
                                                                           object: audioSession,
                                                                           queue: nil) { [weak self] notification in
      print(AVAudioSession.mediaServicesWereLostNotification)
      guard let self = self else {
        return
      }
      self.handleMediaServerWereLost()
    }
    let mediaServicesWereResetNotificationSubscribtion = center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification,
                                                                            object: audioSession,
                                                                            queue: nil) { [weak self] notification in
      print(AVAudioSession.mediaServicesWereResetNotification)
      guard let self = self else {
        return
      }
      self.handleMediaServerWereReset()
    }
    
    return [
      interruptionNotificationSubscribtion,
      routeChangeNotificationSubscribtion,
      mediaServicesWereLostNotificationSubscribtion,
      mediaServicesWereResetNotificationSubscribtion
    ]
  }
  
  func unsubscribeAudioSessionNotifications(observers: [Any]) {
    let center = NotificationCenter.default
    for observer in observers {
      center.removeObserver(observer)
    }
  }

  func configureStereoRecording() {
    // Find the built-in microphone input.
    guard let availableInputs = audioSession.availableInputs,
          let builtInMicInput = availableInputs.first(where: { $0.portType == .builtInMic }) else {
      print("The device must have a built-in microphone.")
      return
    }
    
    // Make the built-in microphone input the preferred input.
    do {
      try audioSession.setPreferredInput(builtInMicInput)
    } catch {
      print("Unable to set the built-in mic as the preferred input.")
      return
    }
    
    
    guard let preferredInput = audioSession.preferredInput,
          let dataSources = preferredInput.dataSources,
          let frontStereo = dataSources.first(where: { $0.orientation == .front }),
          let supportedPolarPatterns = frontStereo.supportedPolarPatterns else {
      print("No polar patterns.")
      return
    }
    var isStereoSupported = false
    do {
      isStereoSupported = supportedPolarPatterns.contains(.stereo)
      // If the data source supports stereo, set it as the preferred polar pattern.
      if isStereoSupported {
        // Set the preferred polar pattern to stereo.
        try frontStereo.setPreferredPolarPattern(.stereo)
      }
      
      // Set the preferred data source and polar pattern.
      try preferredInput.setPreferredDataSource(frontStereo)
      
      // Update the input orientation to match the current user interface orientation.
      try audioSession.setPreferredInputOrientation(.portrait)
      
    } catch {
      fatalError("Unable to select the \(frontStereo.dataSourceName) data source.")
    }
  }
}

import Foundation
import WebRTC
import AVFoundation

// NOTE: Does not cover all corner cases with audio session interruptions, switch between devices etc.
// Please use only as an example
final class AVAudioEngineRTCAudioDevice: NSObject {
  let audioSession = AVAudioSession.sharedInstance()
  private var subscribtions: [Any]?

  private let queue = DispatchQueue(label: "AVAudioEngineRTCAudioDevice")

  private lazy var backgroundPlayer = AVAudioPlayerNode()
  private var backgroundSound: AVAudioPCMBuffer?

  private var audioEngine: AVAudioEngine?
  private var audioEngineObserver: Any?
  private var inputEQ = AVAudioUnitEQ(numberOfBands: 2)

  private var audioConverer: AVAudioConverter?
  private var audioSinkNode: AVAudioSinkNode?
  private var audioSourceNode: AVAudioSourceNode?
  private var shouldPlay = false
  private var shouldRecord = false

  private lazy var audioInputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                                    sampleRate: audioSession.sampleRate,
                                                    channels: AVAudioChannelCount(min(2, audioSession.inputNumberOfChannels)),
                                                    interleaved: false) {
    didSet {
      guard oldValue != audioInputFormat else { return }
      delegate?.notifyAudioInputParametersChange()
    }
  }

  private lazy var audioOutputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                                     sampleRate: audioSession.sampleRate,
                                                     channels: AVAudioChannelCount(min(2, audioSession.outputNumberOfChannels)),
                                                     interleaved: false) {
    didSet {
      guard oldValue != audioOutputFormat else { return }
      delegate?.notifyAudioOutputParametersChange()
    }
  }

  private var isInterrupted_ = false
  private var isInterrupted: Bool {
    get {
      queue.sync {
        isInterrupted_
      }
    }
    set {
      queue.sync {
        isInterrupted_ = newValue
      }
    }
  }

  var delegate_: RTCAudioDeviceDelegate?
  private var delegate: RTCAudioDeviceDelegate? {
    get {
      queue.sync {
        delegate_
      }
    }
    set {
      queue.sync {
        delegate_ = newValue
      }
    }
  }

  private (set) lazy var inputLatency = audioSession.inputLatency {
    didSet {
      guard oldValue != inputLatency else { return }
      delegate?.notifyAudioInputParametersChange()
    }
  }
  
  private (set) lazy var outputLatency = audioSession.outputLatency {
    didSet {
      guard oldValue != outputLatency else { return }
      delegate?.notifyAudioOutputParametersChange()
    }
  }

  override init() {
    super.init()
  }

  private func shutdownEngine() {
    guard let audioEngine = audioEngine else {
      return
    }
    if audioEngine.isRunning {
      audioEngine.stop()
    }
    if let audioEngineObserver = audioEngineObserver {
      NotificationCenter.default.removeObserver(audioEngineObserver)
      self.audioEngineObserver = nil
    }
    if let audioSinkNode = self.audioSinkNode {
      audioEngine.detach(audioSinkNode)
      self.audioSinkNode = nil
      delegate?.notifyAudioInputInterrupted()
    }
    if let audioSourceNode = audioSourceNode {
      audioEngine.detach(audioSourceNode)
      self.audioSourceNode = nil
      delegate?.notifyAudioOutputInterrupted()
    }
    self.audioEngine = nil
  }

  private func updateEngine()  {
    guard let delegate = delegate,
          shouldPlay || shouldRecord,
          !isInterrupted else {
      print("Audio Engine must be stopped: shouldPla=\(shouldPlay), shouldRecord=\(shouldRecord), isInterrupted=\(isInterrupted)")
      measureTime(label: "Shutdown AVAudioEngine") {
        shutdownEngine()
      }
      return
    }

    if let audioEngine = audioEngine, !audioEngine.isInputOutputSampleRatesNativeFor(audioSession: audioSession) {
      print("Shutdown AVAudioEngine to match HW format")
      shutdownEngine()
    }

    let useVoiceProcessingAudioUnit = audioSession.supportsVoiceProcessing
    if let audioEngine = audioEngine, audioEngine.inputNode.isVoiceProcessingEnabled != useVoiceProcessingAudioUnit {
      print("Shutdown AVAudioEngine to toggle usage of Voice Processing I/O")
      shutdownEngine()
    }

    var audioEngine: AVAudioEngine
    if let engine = self.audioEngine {
      audioEngine = engine
    } else {
      if !useVoiceProcessingAudioUnit {
        configureStereoRecording()
      }

      audioEngine = AVAudioEngine()
      audioEngine.isAutoShutdownEnabled = true
      // NOTE: Toggle voice processing state over outputNode, not to eagerly create inputNote.
      // Also do it just after creation of AVAudioEngine to avoid random crashes observed when voice processing changed on later stages.
      if audioEngine.outputNode.isVoiceProcessingEnabled != useVoiceProcessingAudioUnit {
        do {
          // Use VPIO to as I/O audio unit.
          try audioEngine.outputNode.setVoiceProcessingEnabled(useVoiceProcessingAudioUnit)
        }
        catch let e {
          print("setVoiceProcessingEnabled error: \(e)")
          return
        }
      }
      audioEngine.attach(backgroundPlayer)
      audioEngine.attach(inputEQ)

      audioEngineObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVAudioEngineConfigurationChange,
                                                                   object: audioEngine,
                                                                   queue: nil,
                                                                   using: { [weak self] notification in
          self?.handleAudioEngineConfigurationChanged()
      })

      audioEngine.dumpState(label: "State of newly created audio engine")
      self.audioEngine = audioEngine
    }

    let shouldBypassVoiceProcessing = shouldRecord && !shouldPlay
    if useVoiceProcessingAudioUnit {
      if audioEngine.inputNode.isVoiceProcessingBypassed != shouldBypassVoiceProcessing {
        measureTime(label: "Change bypass voice processing") {
          audioEngine.inputNode.isVoiceProcessingBypassed = shouldBypassVoiceProcessing
        }
      }
    }

    let ioAudioUnit = audioEngine.outputNode.auAudioUnit
    if ioAudioUnit.isInputEnabled != shouldRecord ||
        ioAudioUnit.isOutputEnabled != shouldPlay {
      if audioEngine.isRunning {
        measureTime(label: "AVAudioEngine stop (to enable/disable AUAudioUnit output/input)") {
          audioEngine.stop()
        }
      }

      measureTime(label: "Change input/output enabled/disabled") {
        ioAudioUnit.isInputEnabled = shouldRecord
        ioAudioUnit.isOutputEnabled = shouldPlay
      }
    }

    if shouldRecord {
      if audioSinkNode == nil {
        measureTime(label: "Add AVAudioSinkNode") {
          let deliverRecordedData = delegate.deliverRecordedData
          let inputFormat = audioEngine.inputNode.outputFormat(forBus: 1)
          guard inputFormat.isSampleRateAndChannelCountValid else {
            print("Invalid input format: \(inputFormat)")
            return
          }
          audioEngine.connect(audioEngine.inputNode, to: inputEQ, format: inputFormat)

          let rtcRecordFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                              sampleRate: inputFormat.sampleRate,
                                              channels: inputFormat.channelCount,
                                              interleaved: true)!
          audioInputFormat = rtcRecordFormat
          inputLatency = audioSession.inputLatency

          // NOTE: AVAudioSinkNode provides audio data with HW sample rate in 32-bit float format,
          // WebRTC requires 16-bit int format, so do the conversion
          let converter = SimpleAudioConverter(from: inputFormat, to: rtcRecordFormat)!

          let customRenderBlock: RTCAudioDeviceRenderRecordedDataBlock = { actionFlags, timestamp, inputBusNumber, frameCount, abl, renderContext in
            let (converter, inputData) = renderContext!.assumingMemoryBound(to: (Unmanaged<SimpleAudioConverter>, UnsafeMutablePointer<AudioBufferList>).self).pointee
            return converter.takeUnretainedValue().convert(framesCount: frameCount, from: inputData, to: abl)
          }

          let audioSink = AVAudioSinkNode(receiverBlock: { (timestamp, framesCount, inputData) -> OSStatus in
            var flags: AudioUnitRenderActionFlags = []
            var renderContext = (Unmanaged.passUnretained(converter), inputData)
            return deliverRecordedData(&flags, timestamp, 1, framesCount, nil, &renderContext, customRenderBlock)
          })
    
          measureTime(label: "Attach AVAudioSinkNode") {
            audioEngine.attach(audioSink)
          }
          
          measureTime(label: "Connect AVAudioSinkNode") {
            audioEngine.connect(inputEQ, to: audioSink, format: inputFormat)
          }
          
          audioSinkNode = audioSink
        }
      }
    } else {
      if let audioSinkNode = audioSinkNode {
        audioEngine.detach(audioSinkNode)
        self.audioSinkNode = nil
      }
    }

    if shouldPlay {
      if audioSourceNode == nil {
        measureTime(label: "Add AVAudioSourceNode") {
          let outputFormat = audioEngine.outputNode.outputFormat(forBus: 0)
          guard outputFormat.isSampleRateAndChannelCountValid else {
            print("Invalid audio output format detected: \(outputFormat)")
            return
          }
          print("Playout format: \(outputFormat)")
          audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: outputFormat)

          let rtcPlayFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                            sampleRate: outputFormat.sampleRate,
                                            channels: outputFormat.channelCount,
                                            interleaved: true)!

          audioOutputFormat = rtcPlayFormat
          inputLatency = audioSession.inputLatency

          let getPlayoutData = delegate.getPlayoutData
          let audioSource = AVAudioSourceNode(format: rtcPlayFormat,
                                              renderBlock: { (isSilence, timestamp, frameCount, outputData) -> OSStatus in
            var flags: AudioUnitRenderActionFlags = []
            let res = getPlayoutData(&flags, timestamp, 0, frameCount, outputData)
            guard noErr == res else {
              return res
            }
            isSilence.initialize(to: ObjCBool(flags.contains(AudioUnitRenderActionFlags.unitRenderAction_OutputIsSilence)))
            return noErr
          })

          measureTime(label: "Attach AVAudioSourceNode") {
            audioEngine.attach(audioSource)
          }

          measureTime(label: "Connect AVAudioSourceNode") {
            audioEngine.connect(audioSource, to: audioEngine.mainMixerNode, format: outputFormat)
          }

          self.audioSourceNode = audioSource
        }
      }
    } else {
      if let audioSourceNode = audioSourceNode {
        audioEngine.detach(audioSourceNode)
        self.audioSourceNode = nil
      }
    }

    if !audioEngine.isRunning {
      measureTime(label: "Prepare AVAudioEngine") {
        audioEngine.prepare()
      }

      measureTime(label: "Start AVAudioEngine") {
        do {
          try audioEngine.start()
        } catch let e {
          print("Unable to start audio engine: \(e)")
        }
      }

      if let backgroundSound = backgroundSound, audioEngine.isRunning, shouldPlay {
        measureTime(label: "Background music") {
          audioEngine.disconnectNodeOutput(backgroundPlayer)
          audioEngine.connect(backgroundPlayer, to: audioEngine.mainMixerNode, format: nil)
          if !backgroundPlayer.isPlaying {
            backgroundPlayer.play()
            backgroundPlayer.scheduleBuffer(backgroundSound, at: nil, options: [.loops], completionHandler: nil)
          }
        }
      }
    }

    audioEngine.dumpState(label: "After updateEngine")
  }
  
  private func handleAudioEngineConfigurationChanged() {
    guard let delegate = delegate else {
      return
    }
    delegate.dispatchAsync { [weak self] in
      self?.updateEngine()
    }
  }
}

extension AVAudioEngineRTCAudioDevice: RTCAudioDevice {

  var deviceInputSampleRate: Double {
    guard let sampleRate = audioInputFormat?.sampleRate, sampleRate > 0 else {
      return audioSession.sampleRate
    }
    return sampleRate
  }

  var deviceOutputSampleRate: Double {
    guard let sampleRate = audioOutputFormat?.sampleRate, sampleRate > 0 else {
      return audioSession.sampleRate
    }
    return sampleRate
  }

  var inputIOBufferDuration: TimeInterval { audioSession.ioBufferDuration }

  var outputIOBufferDuration: TimeInterval { audioSession.ioBufferDuration }

  var inputNumberOfChannels: Int {
    guard let channelCount = audioInputFormat?.channelCount, channelCount > 0 else {
      return min(2, audioSession.inputNumberOfChannels)
    }
    return Int(channelCount)
  }

  var outputNumberOfChannels: Int {
    guard let channelCount = audioOutputFormat?.channelCount, channelCount > 0 else {
      return min(2, audioSession.outputNumberOfChannels)
    }
    return Int(channelCount)
  }

  var isInitialized: Bool {
    self.delegate != nil
  }

  func initialize(with delegate: RTCAudioDeviceDelegate) -> Bool {
    guard self.delegate == nil else {
      print("Already inititlized")
      return false
    }

    if subscribtions == nil {
      subscribtions = self.subscribeAudioSessionNotifications()
    }

    self.delegate = delegate
    
    if let fxURL = Bundle.main.url(forResource: "Synth", withExtension: "aif") {
      backgroundSound = getBuffer(fileURL: fxURL)
    }
    return true
  }

  func terminateDevice() -> Bool {
    if let subscribtions = subscribtions {
      self.unsubscribeAudioSessionNotifications(observers: subscribtions)
    }
    subscribtions = nil

    shouldPlay = false
    shouldRecord = false
    measureTime {
      updateEngine()
    }
    delegate = nil
    return true
  }

  var isPlayoutInitialized: Bool { isInitialized }

  func initializePlayout() -> Bool {
    return isPlayoutInitialized
  }

  var isPlaying: Bool {
    shouldPlay
  }

  func startPlayout() -> Bool {
    print("Start playout")
    shouldPlay = true
    measureTime {
      updateEngine()
    }
    return true
  }

  func stopPlayout() -> Bool {
    print("Stop playout")
    shouldPlay = false
    measureTime {
      updateEngine()
    }
    return true
  }

  var isRecordingInitialized: Bool { isInitialized }

  func initializeRecording() -> Bool {
    return isRecordingInitialized
  }

  var isRecording: Bool {
    shouldRecord
  }

  func startRecording() -> Bool {
    print("Start recording")
    shouldRecord = true
    measureTime {
      updateEngine()
    }
    return true
  }

  func stopRecording() -> Bool {
    print("Stop recording")
    shouldRecord = false
    measureTime {
      updateEngine()
    }
    return true
  }
}

extension AVAudioEngineRTCAudioDevice: AudioSessionHandler {
  func handleInterruptionBegan(applicationWasSuspended: Bool) {
    guard !applicationWasSuspended else {
      // NOTE: Not an actual interruption
      return
    }
    isInterrupted = true
    guard let delegate = delegate else {
      return
    }
    delegate.dispatchAsync { [weak self] in
      self?.updateEngine()
    }
  }

  func handleInterruptionEnd(shouldResume: Bool) {
    isInterrupted = false
    guard let delegate = delegate else {
      return
    }
    delegate.dispatchAsync { [weak self] in
      self?.updateEngine()
    }
  }

  func handleAudioRouteChange() {
  }

  func handleMediaServerWereReset() {
  }

  func handleMediaServerWereLost() {
  }
}


import Foundation
import CoreAudioTypes
import AVFAudio

public final class SimpleAudioConverter {
  public let from: AVAudioFormat
  public let to: AVAudioFormat
  private var audioConverter: AudioConverterRef?

  public init?(from: AVAudioFormat, to: AVAudioFormat) {
    guard from.sampleRate == to.sampleRate else {
      print("Sample rate conversion is not possible")
      return nil
    }
    guard noErr == AudioConverterNew(from.streamDescription, to.streamDescription, &audioConverter) else {
      return nil
    }
    self.from = from
    self.to = to
  }

  deinit {
    if let audioConverter = audioConverter {
      AudioConverterDispose(audioConverter)
    }
    audioConverter = nil
  }

  public func convert(framesCount: AVAudioFrameCount, from: UnsafePointer<AudioBufferList>, to: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
    guard let audioConverter = audioConverter else {
      preconditionFailure("Not properly inited")
    }
    let status = AudioConverterConvertComplexBuffer(audioConverter, framesCount, from, to)
    return status
  }
}

func requestAudioSession(category: AVAudioSession.Category,
                         mode: AVAudioSession.Mode,
                         options: AVAudioSession.CategoryOptions) async throws {
  return try await withCheckedThrowingContinuation { cont in
    let audioSession = AVAudioSession.sharedInstance()

    audioSession.requestRecordPermission { ok in
      guard ok else {
          fatalError()
      }
      do {
        try audioSession.setCategory(category,
                                     mode: mode,
                                     policy: .default,
                                     options: options)
      } catch {
        print("Set category: \(error)")
        fatalError()
      }

      do {
        try audioSession.setActive(true)
      } catch {
        print("Set active: \(error)")
        fatalError()
      }

      print("Before \(audioSession.describedState)")

      do {
        try audioSession.setPreferredSampleRate(6 * 8000)
      } catch {
        print("Failed to setPreferredSampleRate: \(error)")
      }

      do {
        try audioSession.setPreferredIOBufferDuration(0.02)
      } catch {
        print("Failed to setPreferredIOBufferDuration: \(error)")
      }

      print("After \(audioSession.describedState)")
      cont.resume(with: .success(()))
    }
  }
}
