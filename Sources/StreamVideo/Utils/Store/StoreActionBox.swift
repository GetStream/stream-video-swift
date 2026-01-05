//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight wrapper that pairs an action with optional timing delays.
///
/// Use `.normal` for immediate processing or `.delayed` to apply
/// `before`/`after` delays around reducer execution. This lets callers
/// control timing without complicating the ``Store`` API surface.
enum StoreActionBox<Element: Sendable> {
    case normal(Element)
    case delayed(Element, delay: StoreDelay)

    /// The underlying action, regardless of delay configuration.
    var wrappedValue: Element {
        switch self {
        case let .normal(element):
            return element
        case let .delayed(element, _):
            return element
        }
    }

    /// Applies the configured `before` delay, if any.
    func applyDelayBeforeIfRequired() async {
        switch self {
        case .normal:
            return
        case let .delayed(_, delay):
            return await delay.applyDelayBeforeIfRequired()
        }
    }

    /// Applies the configured `after` delay, if any.
    func applyDelayAfterIfRequired() async {
        switch self {
        case .normal:
            return
        case let .delayed(_, delay):
            return await delay.applyDelayAfterIfRequired()
        }
    }

    func withBeforeDelay(_ delay: TimeInterval) -> Self {
        switch self {
        case let .normal(element):
            return .delayed(element, delay: .init(before: delay))
        case let .delayed(element, currentDelay):
            return .delayed(element, delay: .init(before: delay, after: currentDelay.after))
        }
    }

    func withAfterDelay(_ delay: TimeInterval) -> Self {
        switch self {
        case let .normal(element):
            return .delayed(element, delay: .init(after: delay))
        case let .delayed(element, currentDelay):
            return .delayed(element, delay: .init(before: currentDelay.before, after: delay))
        }
    }
}

/// Opt‑in protocol that makes an action type able to produce a
/// ``StoreActionBox`` using the default, no‑delay semantics.
protocol StoreActionBoxProtocol {
    associatedtype Element: Sendable

    var box: StoreActionBox<Element> { get }
}

extension StoreActionBoxProtocol where Self: Sendable {
    /// Wraps `self` into a `.normal` action box (no delay).
    var box: StoreActionBox<Self> {
        .normal(self)
    }

    func withBeforeDelay(_ delay: TimeInterval) -> StoreActionBox<Self> {
        .delayed(self, delay: .init(before: delay))
    }

    func withAfterDelay(_ delay: TimeInterval) -> StoreActionBox<Self> {
        .delayed(self, delay: .init(after: delay))
    }
}
