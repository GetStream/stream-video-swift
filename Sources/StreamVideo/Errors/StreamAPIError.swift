//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// StreamVideo-facing name for StreamCore's `APIError`.
///
/// This is the canonical API error type for hand-written code; the generated
/// OpenAPI layer keeps its own `APIError`. A distinct alias name is required
/// because the generated `APIError` already occupies the bare name in this
/// module, and referencing `StreamCore.APIError` directly would force
/// `import StreamCore` (which reintroduces `log`/`ClientError`/`APIError`
/// ambiguities) in every consumer. Only stored properties (`code`,
/// `statusCode`, `message`, `unrecoverable`) are read through it, so no import
/// is needed at the use sites.
///
/// - TODO: [StreamCore migration] This alias (and the split between hand-written
///   `StreamAPIError` and the generated `APIError`) goes away once the OpenAPI
///   generator is changed to emit `APIError` as `StreamCore.APIError`. Then the
///   whole app uses one API error type and this file can be deleted.
public typealias StreamAPIError = StreamCore.APIError
