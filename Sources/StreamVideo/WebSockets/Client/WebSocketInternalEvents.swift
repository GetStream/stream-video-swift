//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// Internal marker events emitted on coordinator connect/disconnect. Retained
// from the deleted video `WebSocketClient` since `StreamVideo` still publishes
// them.

struct WSDisconnected: Event {}
struct WSConnected: Event {}
