# StreamVideo iOS SDK CHANGELOG

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

# Upcoming

### 🔄 Changed
- You can now focus on a desired point in the local video stream. [#221](https://github.com/GetStream/stream-video-swift/pull/221)

# [0.4.1](https://github.com/GetStream/stream-video-swift/releases/tag/0.4.1)
_October 16, 2023_

### 🐞 Fixed
- Video tracks remain disabled when they become visible [#191](https://github.com/GetStream/stream-video-swift/pull/191)

# [0.4.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.4.0)
_October 11, 2023_

### ✅ Added
- Picture-in-Picture support
- Livestream Player
- Call stats report

### 🔄 Changed
- Factory method for creating `LocalParticipantViewModifier`
- `availableSize` has been replaced by `availableFrame` in most Views.

### 🐞 Fixed
- Current user overlay view size when camera is off
- Thermal state improvements
- Benchmark tests for up to 1000 users

# [0.3.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.3.0)
_August 25, 2023_

### ✅ Added
- Screensharing from iOS devices
- Remote pinning of users
- Add XCPrivacy manifest
- Custom Audio Filters

### 🔄 Changed
- Factory method for creating `VideoCallParticipantView`
- `VideoCallParticipantView` init method

### 🐞 Fixed
- Stability improvements
- CPU usage improvements

# [0.2.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.2.0)
_July 18, 2023_

### ✅ Added
- SDK version info sent in all requests
- Call participants shown in the lobby view
- Support for setting default audio device
- Improved test coverage

# [0.1.0](https://github.com/GetStream/stream-video-swift/releases/tag/0.1.0)
_July 07, 2023_

### ✅ Added

- StreamVideo iOS SDK 🚀
