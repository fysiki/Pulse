// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import Foundation
import Network
import Combine

@available(iOS 14, tvOS 14, *)
extension RemoteLogger {
    /// Applies the given event to the store.
    public static func process(_ event: LoggerStore.Event, store: LoggerStore) {
        store.handleExternalEvent(event)
    }
}
