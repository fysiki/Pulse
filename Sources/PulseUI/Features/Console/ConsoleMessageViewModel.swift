// The MIT License (MIT)
//
// Copyright (c) 2020–2022 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import PulseCore
import CoreData
import Combine

@available(iOS 13.0, tvOS 14.0, watchOS 7.0, *)
final class ConsoleMessageViewModel {
    let title: String
    let text: String
    let textColor: Color
    let badge: BadgeViewModel?

    let showInConsole: (() -> Void)?

    private let message: LoggerMessageEntity
    private let context: AppContext

    #if os(iOS)
    lazy var attributedTitle: NSAttributedString = {
        let string = NSMutableAttributedString()
        let level = LoggerStore.Level(rawValue: message.level) ?? .debug
        if let badge = badge {
            string.append(badge.title, [.foregroundColor: UIColor.textColor(for: level)])
        }
        string.append(title, [.foregroundColor: UIColor.secondaryLabel])
        return string
    }()
    #endif

    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    lazy var pinViewModel: PinButtonViewModel = {
        PinButtonViewModel(store: context.store, message: message)
    }()

    init(message: LoggerMessageEntity, context: AppContext, showInConsole: (() -> Void)? = nil) {
        let time = ConsoleMessageViewModel.timeFormatter.string(from: message.createdAt)
        if message.label == "default" {
            self.title = time
        } else {
            self.title = "\(time) · \(message.label.capitalized)"
        }
        self.text = message.text
        self.textColor = ConsoleMessageStyle.textColor(level: LoggerStore.Level(rawValue: message.level) ?? .debug)
        self.badge = BadgeViewModel(message: message)
        self.context = context
        self.message = message
        self.showInConsole = showInConsole
    }
}

@available(iOS 13.0, tvOS 14.0, watchOS 6, *)
private extension BadgeViewModel {
    init?(message: LoggerMessageEntity) {
        guard let model = LoggerStore.Level(rawValue: message.level).flatMap(BadgeViewModel.init) else {
            return nil
        }
        self = model
    }

    init?(level: LoggerStore.Level) {
        switch level {
        case .critical: self.init(title: "CRITICAL", color: .red)
        case .error: self.init(title: "ERROR", color: .red)
        case .warning: self.init(title: "WARNING", color: .orange)
        case .info: self.init(title: "INFO", color: .blue)
        case .notice: self.init(title: "NOTICE", color: .indigo)
        case .debug: return nil
        case .trace: return nil
        }
    }
}

@available(iOS 13.0, tvOS 14.0, watchOS 6.0, *)
extension Color {
    static func textColor(for level: LoggerStore.Level) -> Color {
        switch level {
        case .critical: return .red
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        case .notice: return .blue
        case .debug: return .primary
        case .trace: return .primary
        }
    }
}

#if os(iOS)
@available(iOS 13.0, *)
extension UIColor {
    static func textColor(for level: LoggerStore.Level) -> UIColor {
        switch level {
        case .trace: return .secondaryLabel
        case .debug, .info: return .label
        case .notice, .warning: return .systemOrange
        case .error, .critical: return .systemRed
        }
    }
}
#endif

#if os(macOS)
enum ConsoleMessageStyle {
    static func textColor(level: LoggerStore.Level) -> Color {
        switch level {
        case .trace: return .primary
        case .debug: return .primary
        case .info: return .primary
        case .notice: return .orange
        case .warning: return .orange
        case .error: return Color(Palette.red)
        case .critical: return Color(Palette.red)
        }
    }
}
#else
@available(iOS 13.0, tvOS 14.0, watchOS 7.0, *)
enum ConsoleMessageStyle {
    static func textColor(level: LoggerStore.Level) -> Color {
        switch level {
        case .trace: return .primary
        case .debug: return .primary
        case .info: return .primary
        case .notice: return .orange
        case .warning: return .orange
        case .error: return .red
        case .critical: return .red
        }
    }
}
#endif
